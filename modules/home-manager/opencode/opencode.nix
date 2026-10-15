{ config, pkgs, lib, ... }:

let
  modelRoutes = import ./models.nix;
  cfg = config.miguel.opencode;

  makeEngramProfile = import ./engram.nix { inherit config pkgs lib; };
  makeCodegraphProfile = import ./codegraph.nix { inherit pkgs lib; };
  context7 = import ./context7.nix;
  opencodeCandidateId = pkgs.callPackage ./candidate-id.nix { };

  profilePaths = {
    merlin = { directory = "opencode-merlin"; filename = "opencode.json"; };
    personal = { directory = "opencode-personal"; filename = "opencode.json"; };
    inditex = { directory = "opencode-inditex"; filename = "profile.json"; };
  };
  profileConfigDirectory = profile:
    "${config.xdg.configHome}/${profilePaths.${profile}.directory}";

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

      url_file="''${OPENCODE_GITEA_URL_FILE:-/home/miguel/.config/opencode/keys/gitea.url}"
      token_file="''${OPENCODE_GITEA_TOKEN_FILE:-/home/miguel/.config/opencode/keys/gitea.token}"

      if [ ! -r "$url_file" ]; then
        echo "Gitea MCP URL file is missing or unreadable: $url_file" >&2
        exit 1
      fi

      if [ ! -r "$token_file" ]; then
        echo "Gitea MCP token file is missing or unreadable: $token_file" >&2
        exit 1
      fi

      forgejo_url="$(tr -d '\r\n' < "$url_file")"
      forgejo_token="$(tr -d '\r\n' < "$token_file")"

      if [ -z "$forgejo_url" ]; then
        echo "Gitea MCP URL file is empty: $url_file" >&2
        exit 1
      fi

      if [ -z "$forgejo_token" ]; then
        echo "Gitea MCP token file is empty: $token_file" >&2
        exit 1
      fi

      case "$forgejo_url" in
        http://*|https://*) ;;
        *)
          echo "Gitea MCP URL must start with http:// or https://: $url_file" >&2
          exit 1
          ;;
      esac

      token_mode="$(stat -c '%a' "$token_file")"
      if [ $((10#$token_mode % 100)) -ne 0 ]; then
        echo "Gitea MCP token file must not be group/world-readable: $token_file" >&2
        exit 1
      fi

      export FORGEJO_URL="$forgejo_url"
      export FORGEJO_TOKEN="$forgejo_token"
      exec npx -y @ric_/forgejo-mcp@0.1.5
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

  managedConfig = builtins.fromJSON (builtins.readFile (builtins.fetchurl {
    url = "https://llm.merlinsoftware.es/.well-known/opencode/managed-v1.json";
    sha256 = "1bd5hclcaz3lm8k68h6snlf50fp5gjlqqn2i598gp0wanqgyzq6s";
  }));

  modelVariants = {
    "gpt-6.1-sol" = {
      options = { reasoningEffort = "medium"; };
      variants = {
        balanced = { reasoningEffort = "medium"; };
        deep = { reasoningEffort = "high"; textVerbosity = "medium"; };
      };
    };
    "gpt-5.6-terra" = {
      options = { reasoningEffort = "medium"; };
      variants = {
        fast = { reasoningEffort = "low"; };
        balanced = { reasoningEffort = "medium"; };
        deep = { reasoningEffort = "high"; textVerbosity = "medium"; };
      };
    };
  };

  merlinProvider = managedConfig.provider.merlin // {
    models = lib.mapAttrs (modelName: modelDef:
      if builtins.hasAttr modelName modelVariants then
        modelDef // modelVariants.${modelName}
      else
        modelDef
    ) managedConfig.provider.merlin.models;
  };

  personalProvider = {
    "opencode-go" = {
      whitelist = [ "glm-5.3-flash" "kimi-k2.7-code" "minimax-m3" ];
    };
    "opencode" = {
      whitelist = [ "big-pickle" ];
    };
    "openai" = {
      whitelist = [ "gpt-6.1-sol" "gpt-6-luna" ];
    };
  };

  baseConfig = builtins.fromJSON (builtins.readFile ./opencode.json);
  opencodeConfigFor = profile:
    let
      profileRoutes = modelRoutes.${profile};
      agentRoutes = profileRoutes.agents or { };
      routeFor = name:
        if builtins.hasAttr name agentRoutes then agentRoutes.${name}
        else if profile != "inditex" then
          throw "OpenCode ${profile} profile is missing a route for agent '${name}' in modules/home-manager/opencode/models.nix"
        else null;
      smallModel =
        if profileRoutes ? smallModel then profileRoutes.smallModel
        else if profile != "inditex" then
          throw "OpenCode ${profile} profile is missing smallModel in modules/home-manager/opencode/models.nix"
        else null;
      agentConfig = lib.mapAttrs (name: agent:
        let route = routeFor name;
        in (removeAttrs agent [ "model" "variant" ])
          // lib.optionalAttrs (route != null) ({ model = route.model; }
            // lib.optionalAttrs (route ? variant) { variant = route.variant; })
      ) baseConfig.agent;
      sharedConfig = (removeAttrs baseConfig [ "agent" "small_model" "mcp" "provider" ]) // {
        agent = agentConfig;
      } // lib.optionalAttrs (smallModel != null) { small_model = smallModel; };
      baseMcpFor = profile:
        if profile == "merlin" then baseConfig.mcp or { }
        else if profile == "personal" then removeAttrs (baseConfig.mcp or { }) [ "hr-merlin-context" ]
        else { };
      mcpAdditions = profile: {
        engram = engramProfiles.${profile}.mcp;
        codegraph = codegraphProfiles.${profile}.mcp;
        context7 = context7.mcp.context7;
      };
      profileConfig = sharedConfig
        // lib.optionalAttrs (profile == "merlin") {
          provider = { merlin = merlinProvider; };
        }
        // lib.optionalAttrs (profile == "personal") {
          provider = personalProvider;
        }
        // {
          mcp = baseMcpFor profile // mcpAdditions profile;
        };
    in lib.recursiveUpdate profileConfig
      (lib.optionalAttrs (profile == "merlin" && cfg.hrMerlinContext.enable) {
        mcp."hr-merlin-context" = {
          type = "remote";
          url = "https://hr-api.merlinsoftware.es/mcp";
          enabled = true;
          oauth = false;
          headers.Authorization = "Bearer {file:/home/miguel/.config/opencode/keys/hr-merlin-context.token}";
          timeout = 60000;
        };
      });

  profilePackages = profile: with pkgs;
    [ opencode nodejs opencodeCandidateId stablyai-orca ]
    ++ lib.optionals (profile == "merlin" || profile == "personal") [
      docker-client
      trivy
      trivyMcp
      giteaMcp
      trivyDockerScan
    ]
    ++ [
      engramProfiles.${profile}.engramPackage
      engramProfiles.${profile}.wrapper
      codegraphProfiles.${profile}.codegraphPackage
      codegraphProfiles.${profile}.wrapper
    ];
  opencodeLauncher = profile:
    let
      profilePath = profilePaths.${profile};
      configDirectory = profileConfigDirectory profile;
    in pkgs.writeShellApplication {
      name = "opencode-${profile}";
      text = ''
        unset OPENCODE_CONFIG OPENCODE_CONFIG_DIR OPENCODE_CONFIG_CONTENT
        export OPENCODE_CONFIG_DIR=${lib.escapeShellArg configDirectory}
        ${lib.optionalString (profilePath.filename == "profile.json")
          "export OPENCODE_CONFIG=${lib.escapeShellArg "${configDirectory}/${profilePath.filename}"}"}
        exec ${pkgs.opencode}/bin/opencode "$@"
      '';
    };
  orcaProfile = if lib.elem "personal" cfg.enabledProfiles then "personal" else "inditex";
  opencodeOrca = pkgs.writeShellApplication {
    name = "opencode-orca";
    text = ''
      exec ${opencodeLauncher orcaProfile}/bin/opencode-${orcaProfile} "$@"
    '';
  };
  profileFiles = lib.concatMap (profile:
    let profilePath = profilePaths.${profile};
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
      {
        name = "opencode-${profile}.agent-prompts";
        value = {
          source = ./agent-prompts;
          target = ".config/${profilePath.directory}/agent-prompts";
          recursive = true;
          force = true;
        };
      }
      {
        name = "opencode-${profile}.commands";
        value = {
          source = ./commands;
          target = ".config/${profilePath.directory}/commands";
          recursive = true;
          force = true;
        };
      }
      {
        name = "opencode-${profile}.skills";
        value = {
          source = ./skills;
          target = ".config/${profilePath.directory}/skills";
          recursive = true;
          force = true;
        };
      }
    ]) cfg.enabledProfiles;
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
        ++ lib.optionals (lib.elem "personal" cfg.enabledProfiles || lib.elem "inditex" cfg.enabledProfiles) [ opencodeOrca ]
      );

      shellAliases = {
        opencode = "opencode-${cfg.profile}";
      };

      file = lib.listToAttrs profileFiles;
    };
  };
}
