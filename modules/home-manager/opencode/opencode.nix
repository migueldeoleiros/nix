{ config, pkgs, lib, ... }:

let
  cfg = config.miguel.opencode;
  profiles = import ./profiles.nix {
    inherit lib;
    hrMerlinContextEnabled = cfg.hrMerlinContext.enable;
  };
  profileFor = profile:
    profiles.${profile} or (throw "OpenCode profile '${profile}' is missing from modules/home-manager/opencode/profiles.nix");

  makeEngramProfile = import ./engram.nix { inherit config pkgs lib; };
  makeCodegraphProfile = import ./codegraph.nix { inherit pkgs lib; };
  context7 = import ./context7.nix;
  agentSecrets = config.miguel.agentSecrets.package;
  makeEmail = import ./email.nix {
    inherit config pkgs lib;
    agentSecretsPackage = agentSecrets;
  };
  opencodeCandidateId = pkgs.callPackage ./candidate-id.nix { };

  profilePaths = {
    merlin = { directory = "opencode-merlin"; filename = "opencode.json"; };
    personal = { directory = "opencode-personal"; filename = "opencode.json"; };
    inditex = { directory = "opencode-inditex"; filename = "opencode.json"; };
  };
  profileConfigDirectory = profile:
    "${config.xdg.configHome}/${profilePaths.${profile}.directory}";

  sharedAssets = ../../../agent-prompts;
  resolveAgentPrompt = name:
    let source = sharedAssets + "/agents/${name}.md";
    in if !builtins.pathExists source then
      throw "OpenCode agent prompt '${name}' is missing from agent-prompts/agents."
    else builtins.seq (builtins.readFile source) source;
  sharedSkillRoot = sharedAssets + "/skills";
  skillNames = builtins.attrNames (if builtins.pathExists sharedSkillRoot then builtins.readDir sharedSkillRoot else { });
  resolveSkill = name:
    let
      selected = sharedSkillRoot + "/${name}";
      skillFile = selected + "/SKILL.md";
    in if !builtins.pathExists selected then
      throw "OpenCode shared skill '${name}' is missing."
    else if !builtins.pathExists skillFile then
      throw "OpenCode shared skill '${name}' is missing SKILL.md in ${toString selected}."
    else builtins.seq (builtins.readFile skillFile) selected;

  engramProfiles = lib.genAttrs cfg.enabledProfiles makeEngramProfile;
  codegraphProfiles = lib.genAttrs cfg.enabledProfiles makeCodegraphProfile;

  trivyMcp = pkgs.writeShellApplication {
    name = "opencode-trivy-mcp";
    runtimeInputs = with pkgs; [ gnugrep trivy ];
    text = ''
      set -euo pipefail

      if ! trivy plugin list 2>/dev/null | grep -q '^mcp[[:space:]]'; then
        trivy plugin install mcp
      fi

      exec trivy mcp
    '';
  };

  giteaMcp = pkgs.writeShellApplication {
    name = "opencode-gitea-mcp";
    runtimeInputs = with pkgs; [ coreutils nodejs ];
    text = ''
      set -euo pipefail
      set +x

      forgejo_url="$(${agentSecrets}/bin/agent-secrets read --trim-eol gitea-url)"
      forgejo_token="$(${agentSecrets}/bin/agent-secrets read --trim-eol gitea-token)"

      if [ -z "$forgejo_url" ]; then
        echo "Gitea MCP URL is empty in the keyring" >&2
        exit 1
      fi

      case "$forgejo_url" in
        http://*|https://*) ;;
        *)
          echo "Gitea MCP URL must start with http:// or https://" >&2
          exit 1
          ;;
      esac

      export FORGEJO_URL="$forgejo_url"
      export FORGEJO_TOKEN="$forgejo_token"
      exec npx -y @ric_/forgejo-mcp@0.1.5
    '';
  };

  sonarqubeMcp = pkgs.writeShellApplication {
    name = "opencode-sonarqube-mcp";
    runtimeInputs = with pkgs; [ coreutils docker-client ];
    text = ''
      set +x
      SONARQUBE_URL="$(${agentSecrets}/bin/agent-secrets read --trim-eol sonarqube-url)"
      case "$SONARQUBE_URL" in
        http://*|https://*) ;;
        *) echo "SonarQube MCP URL must start with http:// or https://" >&2; exit 1 ;;
      esac
      SONARQUBE_TOKEN="$(${agentSecrets}/bin/agent-secrets read --trim-eol sonarqube-token)"
      export SONARQUBE_URL SONARQUBE_TOKEN
      exec docker run --init --rm --network=host -i \
        -e SONARQUBE_TOKEN -e SONARQUBE_URL mcp/sonarqube
    '';
  };

  trivyDockerScan = pkgs.writeShellApplication {
    name = "trivy-docker-scan";
    runtimeInputs = with pkgs; [ docker-client trivy ];
    text = ''
      set -euo pipefail

      image="''${1:-$(basename "$PWD"):local}"
      context="''${2:-.}"
      severity="''${TRIVY_SEVERITY:-HIGH,CRITICAL}"
      scanners="''${TRIVY_SCANNERS:-vuln,secret,misconfig,license}"

      docker build -t "$image" "$context"
      trivy image \
        --scanners "$scanners" \
        --severity "$severity" \
        --exit-code 1 \
        "$image"
    '';
  };

  # Definitions and supporting packages live together; profiles only select names.
  mcpRegistryFor = profile: {
    gitea = {
      mcp = { type = "local"; disabled = false; command = [ "opencode-gitea-mcp" ]; timeout = { catalog = 60000; execution = 60000; }; };
      packages = [ giteaMcp ];
    };
    sonarqube = {
      mcp = {
        type = "local";
        disabled = false;
        command = [ "${sonarqubeMcp}/bin/opencode-sonarqube-mcp" ];
        timeout = { catalog = 60000; execution = 60000; };
      };
      packages = [ sonarqubeMcp ];
    };
    trivy = {
      mcp = { type = "local"; disabled = false; command = [ "opencode-trivy-mcp" ]; timeout = { catalog = 120000; execution = 120000; }; };
      packages = [ pkgs.trivy trivyMcp trivyDockerScan pkgs.docker-client ];
    };
    engram = {
      mcp = engramProfiles.${profile}.mcp;
      packages = [ engramProfiles.${profile}.engramPackage engramProfiles.${profile}.wrapper ];
    };
    codegraph = {
      mcp = codegraphProfiles.${profile}.mcp;
      packages = [ codegraphProfiles.${profile}.codegraphPackage codegraphProfiles.${profile}.wrapper ];
    };
    context7 = { mcp = context7.mcp.context7; packages = [ ]; };
    email = let email = makeEmail (profileFor profile).email; in {
      mcp = email.mcp;
      packages = [ email.wrapper ];
    };
    "hr-merlin-context" = {
      mcp = {
        type = "remote";
        url = "https://hr-api.merlinsoftware.es/mcp";
        disabled = false;
        oauth = false;
        headers.Authorization = "Bearer {file:{env:OPENCODE_HR_TOKEN_FILE}}";
        timeout = { catalog = 60000; execution = 60000; };
      };
      packages = [ ];
    };
  };
  selectedServersFor = profile:
    let registry = mcpRegistryFor profile;
    in lib.genAttrs (profileFor profile).mcp (name:
      if name == "hr-merlin-context" && !(profile == "merlin" && cfg.hrMerlinContext.enable) then
        throw "OpenCode hr-merlin-context requires the merlin profile and miguel.opencode.hrMerlinContext.enable."
      else if name == "email" && profile != "personal" then
        throw "OpenCode email is restricted to the personal profile."
      else registry.${name} or (throw "OpenCode ${profile} profile selects unknown MCP '${name}' in modules/home-manager/opencode/profiles.nix"));

  baseConfig = builtins.fromJSON (builtins.readFile ./opencode.json);
  # Command frontmatter uses an explicit, unquoted `agent: name` line. Keep
  # metadata checked against that convention, without introducing a YAML parser.
  commandAgents = {
    debug = "build";
    pr-review = "reviewer";
    review = "reviewer";
    tech-test-review = "reviewer";
    verify = "verifier";
  };
  commandRegistry = lib.mapAttrs (name: agent:
    let
      adapter = builtins.readFile (sharedAssets + "/adapters/opencode/${name}.md");
      body = builtins.readFile (sharedAssets + "/commands/${name}.md");
      text = builtins.replaceStrings [ "@BODY@" ] [ (builtins.replaceStrings
        [ "@ARGUMENTS@" ] [ "$ARGUMENTS" ] body) ] adapter;
      sections = lib.splitString "---\n" text;
      frontmatter = if builtins.length sections > 1 then lib.splitString "\n" (builtins.elemAt sections 1) else [ ];
      targets = builtins.filter (line: builtins.match "[ \t]*agent[ \t]*:.*" line != null) frontmatter;
    in if builtins.length sections < 3 || builtins.head sections != ""
      || targets != [ "agent: ${agent}" ] then
      throw "OpenCode command '${name}' must declare 'agent: ${agent}' in its frontmatter; update commandAgents in opencode.nix when changing targets."
    else { inherit text agent; }
  ) commandAgents;
  skillRegistry = lib.genAttrs skillNames resolveSkill;
  selectedAssetsFor = profile:
    let
      selections = profileFor profile;
      select = kind: registry: names: lib.genAttrs names (name:
        registry.${name} or (throw "OpenCode ${profile} profile selects unknown ${kind} '${name}' in modules/home-manager/opencode/profiles.nix"));
      agents = select "agent" baseConfig.agents selections.enabledAgents;
      commands = select "command" commandRegistry selections.commands;
      skills = select "skill" skillRegistry selections.skills;
      invalidCommands = lib.filterAttrs (_: command: !(builtins.hasAttr command.agent agents)) commands;
    in builtins.deepSeq [ agents commands skills ] (
      if !(builtins.hasAttr baseConfig.default_agent agents) then
        throw "OpenCode ${profile} profile must select default_agent '${baseConfig.default_agent}'."
      else if invalidCommands != { } then
        throw "OpenCode ${profile} profile commands target unselected agents: ${lib.concatStringsSep ", " (builtins.attrNames invalidCommands)}"
      else { inherit agents commands skills; });
  opencodeConfigFor = profile:
    let
      profileRoutes = profileFor profile;
      agentRoutes = profileRoutes.agents or { };
      routeFor = name:
        if builtins.hasAttr name agentRoutes then agentRoutes.${name}
        else if !profileRoutes.externalModels then
          throw "OpenCode ${profile} profile is missing a route for agent '${name}' in modules/home-manager/opencode/profiles.nix"
        else null;
      smallModel =
        if profileRoutes ? smallModel then profileRoutes.smallModel
        else if !profileRoutes.externalModels then
          throw "OpenCode ${profile} profile is missing smallModel in modules/home-manager/opencode/profiles.nix"
        else null;
      agentConfig = lib.mapAttrs (name: agent:
        let route = routeFor name;
        in (removeAttrs agent [ "model" ])
          // lib.optionalAttrs (lib.elem "email" profileRoutes.mcp && !lib.elem name [ "browser" "email" ]) {
            # Browser's full authority is intentional. Other managed agents
            # get mail reads, with writes reserved for user-facing primaries.
            permissions = (agent.permissions or [ ]) ++ [
              { action = "email_*"; resource = "*"; effect = "deny"; }
            ] ++ map (tool: { action = "email_${tool}"; resource = "*"; effect = "allow"; }) [
              "list_available_accounts" "list_allowed_recipients" "list_allowed_senders"
              "list_email_tags" "list_mailboxes" "list_emails_metadata" "get_emails_content"
            ] ++ lib.optionals (lib.elem name [ "assistant" "build" "quick" ]) (
              map (tool: { action = "email_${tool}"; resource = "*"; effect = "ask"; })
                [ "send_email" "forward_email" "save_draft" ]
            );
          }
          // lib.optionalAttrs (route != null) { model = route.model; }
      ) (selectedAssetsFor profile).agents;
      sharedConfig = (removeAttrs baseConfig [ "agents" "mcp" "providers" "plugins" ]) // {
        # Title is an upstream internal agent, not a selected managed prompt asset.
        agents = agentConfig // lib.optionalAttrs (smallModel != null) { title.model = smallModel; };
      };
    in sharedConfig // {
      plugins = profileRoutes.plugins;
      mcp.servers = lib.mapAttrs (_: server:
        server.mcp // lib.optionalAttrs (server.mcp.type == "local") {
          # MCP tools keep their normal data roots, not OpenCode's private roots.
          environment = (server.mcp.environment or { }) // {
            XDG_DATA_HOME = config.xdg.dataHome;
            XDG_STATE_HOME = config.xdg.stateHome;
            XDG_CACHE_HOME = config.xdg.cacheHome;
          };
        }) (selectedServersFor profile);
    } // lib.optionalAttrs (profileRoutes ? model) { model = profileRoutes.model; }
      // lib.optionalAttrs (profileRoutes ? providers) { providers = profileRoutes.providers; };

  profilePackages = profile: with pkgs;
    [ opencode nodejs opencodeCandidateId stablyai-orca ]
    ++ lib.concatMap (server: server.packages) (lib.attrValues (selectedServersFor profile));
  # Reuse the pinned CLI's parser, but copy just this dependency-free package so
  # launcher runtime references do not retain the entire upstream node_modules.
  launcherJsoncParser = pkgs.runCommand "opencode-launcher-jsonc-parser" { } ''
    mkdir -p "$out"
    cp -RL ${pkgs.opencode.node_modules}/packages/cli/node_modules/jsonc-parser/. "$out/"
  '';
  withRuntimeCredentials = import ../agent-secrets/runtime-files.nix {
    inherit lib pkgs;
    agentSecretsPackage = agentSecrets;
  };
  opencodeLauncher = profile:
    let
      configDirectory = profileConfigDirectory profile;
      launcher = pkgs.writeShellApplication {
      name = "opencode-${profile}";
      text = ''
        unset OPENCODE_CONFIG OPENCODE_CONFIG_DIR OPENCODE_CONFIG_CONTENT OPENCODE_DB
        # Like the server overlay, inherited client overlays belong to neither profile.
        unset OPENCODE_CLI_CONFIG_CONTENT
        export OPENCODE_CONFIG_DIR=${lib.escapeShellArg configDirectory}
        ${lib.optionalString (profile == "merlin" && cfg.hrMerlinContext.enable) ''
          case " ''${AGENT_CREDENTIALS_MISSING:-} " in
            *" OPENCODE_HR_TOKEN_FILE "*)
              export OPENCODE_CONFIG_CONTENT=${lib.escapeShellArg (builtins.toJSON {
                mcp.servers."hr-merlin-context".disabled = true;
              })}
              echo "OpenCode: HR context disabled for this session; continuing startup" >&2
              ;;
          esac
        ''}
        ${lib.optionalString (profile == "inditex") ''
          # Read corporate providers at launch, never during Nix evaluation.
          # Project MCPs/skills/tools remain owned by the AIContext runtime.
          provider_directory="''${OPENCODE_INDITEX_PROVIDER_DIR:-${config.xdg.configHome}/opencode}"
          provider_overlay="$(${pkgs.nodejs}/bin/node ${./launcher-helper.mjs} providers "$provider_directory" ${launcherJsoncParser})"
          export OPENCODE_CONFIG_CONTENT="$provider_overlay"
        ''}
        export XDG_DATA_HOME=${lib.escapeShellArg "${config.xdg.dataHome}/opencode-v2/${profile}"}
        export XDG_STATE_HOME=${lib.escapeShellArg "${config.xdg.stateHome}/opencode-v2/${profile}"}
        export XDG_CACHE_HOME=${lib.escapeShellArg "${config.xdg.cacheHome}/opencode-v2/${profile}"}
        cli_overlay="$(${pkgs.nodejs}/bin/node ${./launcher-helper.mjs} plugins "$OPENCODE_CONFIG_DIR/cli.json" ${launcherJsoncParser} ${lib.escapeShellArg "${config.xdg.configHome}/opencode/plugins/orca-opencode2-status-tui"})"
        export OPENCODE_CLI_CONFIG_CONTENT="$cli_overlay"

        # service.json and cli.json remain writable, client-owned preferences.
        # Only commands supporting private servers receive the flag (before --).
        insert="$(${pkgs.nodejs}/bin/node ${./launcher-helper.mjs} standalone "$@")"
        args=("$@")
        if (( insert >= 0 )); then
          args=("''${args[@]:0:insert}" --standalone "''${args[@]:insert}")
        fi
        exec ${pkgs.opencode}/bin/opencode "''${args[@]}"
      '';
    };
    in if profile == "merlin" && cfg.hrMerlinContext.enable then
      withRuntimeCredentials {
        name = "opencode-${profile}";
        credentials.OPENCODE_HR_TOKEN_FILE = {
          name = "hr-merlin-context-token";
          trimEol = true;
        };
        required = false;
        command = [ "${launcher}/bin/opencode-${profile}" ];
      }
    else launcher;
  orcaProfile = if lib.elem "personal" cfg.enabledProfiles then "personal" else "inditex";
  opencodeOrca = pkgs.writeShellApplication {
    name = "opencode-orca";
    text = ''
      exec ${opencodeLauncher orcaProfile}/bin/opencode-${orcaProfile} "$@"
    '';
  };
  # Private PATH entry, not a replacement for the system/ASDF opencode binary.
  aicontextOpenCode = pkgs.writeShellScriptBin "opencode" ''
    exec ${opencodeLauncher "inditex"}/bin/opencode-inditex "$@"
  '';
  aicontextInditex = pkgs.writeShellApplication {
    name = "aicontext-inditex";
    text = ''
      if ! command -v aicontext >/dev/null 2>&1; then
        echo "aicontext-inditex: install the corporate AIContext CLI first" >&2
        exit 1
      fi
      # Keep AIContext's cwd, arguments, credentials, and installed tools.
      # Both CLI launch and a console started here inherit this scoped shim.
      export PATH=${aicontextOpenCode}/bin:"$PATH"
      exec aicontext "$@"
    '';
  };
  profileFiles = lib.concatMap (profile:
    let
      profilePath = profilePaths.${profile};
      assets = selectedAssetsFor profile;
    in [
      {
        name = "opencode-${profile}.${profilePath.filename}";
        value = {
          text = builtins.toJSON (opencodeConfigFor profile);
          target = ".config/${profilePath.directory}/${profilePath.filename}";
          force = true;
        };
      }
      {
        name = "opencode-${profile}.dcp.json";
        value = {
          source = ./dcp.json;
          target = ".config/${profilePath.directory}/dcp.json";
          force = true;
        };
      }
      {
        name = "opencode-${profile}.gitignore";
        value = {
          text = ''
            node_modules
            package.json
            package-lock.json
            bun.lock
            .gitignore
          '';
          target = ".config/${profilePath.directory}/.gitignore";
          force = true;
        };
      }
    ] ++ lib.mapAttrsToList (name: agent: {
        name = "opencode-${profile}.agent-prompts.${name}";
        value = {
          # Fail closed if the shared definition stops following the prompt convention.
          source = if agent.system == "{file:./agent-prompts/${name}.md}" then
            resolveAgentPrompt name
          else throw "OpenCode agent '${name}' must reference agent-prompts/${name}.md.";
          target = ".config/${profilePath.directory}/agent-prompts/${name}.md";
          force = true;
        };
      }) assets.agents
      ++ lib.mapAttrsToList (name: command: {
        name = "opencode-${profile}.commands.${name}";
        value = {
          text = command.text;
          target = ".config/${profilePath.directory}/commands/${name}.md";
          force = true;
        };
      }) assets.commands
      ++ lib.mapAttrsToList (name: source: {
        name = "opencode-${profile}.skills.${name}";
        value = {
          inherit source;
          target = ".config/${profilePath.directory}/skills/${name}";
          recursive = true;
          force = true;
        };
      }) assets.skills) cfg.enabledProfiles;
in
{
  options.miguel.opencode.hrMerlinContext = {
    enable = lib.mkEnableOption "the hr-merlin-context OpenCode MCP server";
  };

  options.miguel.opencode.profile = lib.mkOption {
    type = lib.types.enum [ "merlin" "personal" "inditex" ];
    default = "merlin";
    description = "OpenCode configuration profile.";
  };

  options.miguel.opencode.enabledProfiles = lib.mkOption {
    type = lib.types.listOf (lib.types.enum [ "merlin" "personal" "inditex" ]);
    default = [ cfg.profile ];
    description = "OpenCode profiles to materialize.";
  };

  config = {
    assertions = [
      {
        assertion = config.miguel.agentSecrets.enable or false;
        message = "OpenCode credential consumers require miguel.agentSecrets.enable.";
      }
      {
        assertion = lib.elem cfg.profile cfg.enabledProfiles;
        message = "miguel.opencode.enabledProfiles must contain miguel.opencode.profile.";
      }
      {
        assertion = !cfg.hrMerlinContext.enable
          || (cfg.profile == "merlin" && lib.elem "merlin" cfg.enabledProfiles);
        message = "miguel.opencode.hrMerlinContext requires profile = \"merlin\" and merlin in enabledProfiles.";
      }
    ];

    home = {
      packages = lib.unique (
        lib.concatMap profilePackages cfg.enabledProfiles
        ++ lib.map opencodeLauncher cfg.enabledProfiles
        ++ lib.optional (lib.elem "inditex" cfg.enabledProfiles) aicontextInditex
        ++ lib.optionals (lib.elem "personal" cfg.enabledProfiles || lib.elem "inditex" cfg.enabledProfiles) [ opencodeOrca ]
      );

      shellAliases = {
        opencode = "opencode-${cfg.profile}";
      } // lib.optionalAttrs (cfg.profile == "inditex") {
        aicontext = "aicontext-inditex";
      };

      file = lib.listToAttrs profileFiles;
    };
  };
}
