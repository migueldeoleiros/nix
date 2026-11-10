{ config, lib, pkgs, piMcpConfig, ... }:

let
  cfg = config.miguel.pi;
  profiles = import ./config/profiles.nix;
  extensions = import ./config/extensions.nix;
  subagentTemplate = builtins.readFile (sharedAssets + "/templates/pi-subagent.md");

  renderSubagent = profile: role: source:
    let
      roleModel = profiles.${profile}.roleModels.${role} or null;
    in builtins.replaceStrings
      [ "@ROLE@" "@MODEL_FIELDS@" "@VERIFIER_FIELDS@" "@ROLE_BODY@" ]
      [ role
        (lib.optionalString (roleModel != null)
          "model: ${roleModel.provider}/${roleModel.modelId}\nthinking: ${roleModel.thinkingLevel}\n")
        (lib.optionalString (role == "verifier")
          "tools: read, grep, find, ls, bash\nsubagent_agents: browser\n")
        (builtins.readFile source)
      ] subagentTemplate;

  sharedAssets = ../../../agent-prompts;
  resolveRole = name:
    let source = sharedAssets + "/agents/${name}.md";
    in if !builtins.pathExists source then
      throw "Pi role '${name}' is missing from agent-prompts/agents."
    else builtins.seq (builtins.readFile source) source;

  resolveSkill = name:
    let
      selected = sharedAssets + "/skills/${name}";
      skillFile = selected + "/SKILL.md";
    in if !builtins.pathExists selected then
      throw "Pi shared skill '${name}' is missing."
    else if !builtins.pathExists skillFile then
      throw "Pi shared skill '${name}' is missing SKILL.md in ${toString selected}."
    else builtins.seq (builtins.readFile skillFile) selected;

  profileFiles = lib.concatMap (profile:
    let
      selections = profiles.${profile};
      root = ".config/pi-${profile}";
      commandDefaults = import ./config/commands.nix;
      commands = builtins.attrNames commandDefaults;
      roleFiles = lib.genAttrs selections.roles resolveRole;
    in [
      {
        name = "pi-${profile}.primary-roles";
        value = {
          target = "${root}/roles.json";
          text = builtins.toJSON selections.roles;
          force = true;
        };
      }
      {
        name = "pi-${profile}.role-models";
        value = {
          target = "${root}/role-models.json";
          text = builtins.toJSON selections.roleModels;
          force = true;
        };
      }
      {
        name = "pi-${profile}.role-colors";
        value = {
          target = "${root}/role-colors.json";
          text = builtins.toJSON (lib.filterAttrs (role: _: lib.elem role selections.roles) selections.roleColors);
          force = true;
        };
      }
      {
        name = "pi-${profile}.mcp";
        value = {
          target = "${root}/mcp.json";
          text = builtins.toJSON (piMcpConfig profile);
          force = true;
        };
      }
    ]
    ++ lib.optional extensions.primaryRole {
      name = "pi-${profile}.extension.primary-role";
      value = {
        source = ./extensions/role-switch.js;
        target = "${root}/extensions/role-switch.js";
        force = true;
      };
    }
    ++ lib.optional extensions.subagents {
      name = "pi-${profile}.extension.pi-subagents";
      value = {
        source = "${pkgs.pi-interactive-subagents}/lib/node_modules/pi-interactive-subagents";
        target = "${root}/extensions/pi-subagents";
        force = true;
      };
    }
    ++ lib.mapAttrsToList (name: source: {
      name = "pi-${profile}.role.${name}";
      value = {
        inherit source;
        target = "${root}/prompts/${name}.md";
        force = true;
      };
    }) roleFiles
    ++ lib.mapAttrsToList (name: source: {
      name = "pi-${profile}.subagent-role.${name}";
      value = {
        target = "${root}/agents/${name}.md";
        text = renderSubagent profile name source;
        force = true;
      };
    }) roleFiles
    ++ map (name:
      let
        adapter = builtins.readFile (sharedAssets + "/adapters/pi/${name}.md");
        body = builtins.readFile (sharedAssets + "/commands/${name}.md");
        rendered = builtins.replaceStrings
          [ "@BODY@" ] [ (builtins.replaceStrings
            [ "@ARGUMENTS@" ]
            [ ("$" + "{@:-${commandDefaults.${name}}}") ] body) ]
          adapter;
      in {
        name = "pi-${profile}.prompt.${name}";
        value = {
          text = rendered;
          target = "${root}/prompts/${name}.md";
          force = true;
        };
      }) commands
    ++ map (name: {
      name = "pi-${profile}.skill.${name}";
      value = {
        source = resolveSkill name;
        target = "${root}/skills/${name}";
        recursive = true;
        force = true;
      };
    }) selections.skills
  ) cfg.enabledProfiles;
in
{
  home.file = lib.listToAttrs profileFiles;
}
