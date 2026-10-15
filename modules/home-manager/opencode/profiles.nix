{ lib, hrMerlinContextEnabled }:

let
  commonAgents = [
    "quick" "assistant" "build" "plan" "investigate" "reviewer" "verifier"
    "spec-writer" "general" "worker" "browser"
  ];
  commonCommands = [ "debug" "pr-review" "review" "tech-test-review" "verify" ];
  commonSkills = [
    "browser-devtools-investigation" "code-review" "codegraph-context7" "debugging"
    "engram-memory" "exploration-deep-dive" "frontend-visual-verification" "java"
    "plan-review" "pr-review" "react" "skill-maintenance" "tech-test-review" "verification"
  ];
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
in {
  merlin = {
    enabledAgents = commonAgents ++ [ "gitea-repo" ];
    commands = commonCommands;
    skills = commonSkills ++ [
      "gitea-ci-investigation" "gitea-issue-triage" "gitea-pr-management"
      "gitea-release-changelog" "sonarqube-review"
    ];
    externalModels = false;
    mcp = [ "gitea" "sonarqube" "trivy" "engram" "codegraph" "context7" ]
      ++ lib.optional hrMerlinContextEnabled "hr-merlin-context";
    plugins = [ "opencode-vibeguard" "@tarquinen/opencode-dcp" "@mohak34/opencode-notifier" ];
    provider.merlin = managedConfig.provider.merlin // {
      models = lib.mapAttrs (modelName: modelDef:
        if builtins.hasAttr modelName modelVariants then
          modelDef // modelVariants.${modelName}
        else modelDef
      ) managedConfig.provider.merlin.models;
    };
    smallModel = "merlin/gpt-6-luna";
    agents = {
      quick = { model = "opencode/big-pickle"; };
      assistant = { model = "merlin/gpt-6.1-sol"; variant = "balanced"; };
      build = { model = "merlin/gpt-6.1-sol"; variant = "balanced"; };
      plan = { model = "merlin/gpt-6.1-sol"; variant = "balanced"; };
      investigate = { model = "merlin/gpt-5.6-terra"; variant = "fast"; };
      reviewer = { model = "merlin/gpt-6.1-sol"; variant = "deep"; };
      verifier = { model = "merlin/gpt-5.6-terra"; variant = "fast"; };
      "spec-writer" = { model = "merlin/gpt-5.6-terra"; variant = "fast"; };
      general = { model = "merlin/gpt-5.6-terra"; variant = "fast"; };
      worker = { model = "merlin/gpt-5.6-terra"; variant = "balanced"; };
      browser = { model = "merlin/gpt-5.6-terra"; variant = "fast"; };
      "gitea-repo" = { model = "merlin/gpt-5.6-terra"; variant = "balanced"; };
    };
  };

  personal = {
    enabledAgents = commonAgents;
    commands = commonCommands;
    skills = commonSkills;
    externalModels = false;
    mcp = [ "engram" "codegraph" "context7" ];
    plugins = [ "opencode-vibeguard" "@tarquinen/opencode-dcp" "@mohak34/opencode-notifier" ];
    provider = {
      "opencode-go".whitelist = [ "glm-5.3-flash" "kimi-k2.7-code" "minimax-m3" ];
      "opencode".whitelist = [ "big-pickle" ];
      "openai".whitelist = [ "gpt-6.1-sol" "gpt-6-luna" ];
    };
    smallModel = "opencode-go/glm-5.3-flash";
    agents = {
      quick = { model = "opencode/big-pickle"; };
      assistant = { model = "openai/gpt-6.1-sol"; };
      build = { model = "openai/gpt-6.1-sol"; };
      plan = { model = "openai/gpt-6.1-sol"; };
      investigate = { model = "opencode-go/glm-5.3-flash"; };
      reviewer = { model = "openai/gpt-6.1-sol"; };
      verifier = { model = "opencode-go/glm-5.3-flash"; };
      "spec-writer" = { model = "openai/gpt-6-luna"; };
      general = { model = "openai/gpt-6-luna"; };
      worker = { model = "openai/gpt-6.1-sol"; };
      browser = { model = "opencode-go/glm-5.3-flash"; };
      "gitea-repo" = { model = "openai/gpt-6-luna"; };
    };
  };

  inditex = {
    enabledAgents = commonAgents;
    commands = commonCommands;
    skills = commonSkills;
    # Other models/providers remain externally selected by corporate configuration.
    externalModels = true;
    mcp = [ "engram" "codegraph" "context7" ];
    plugins = [ "opencode-vibeguard" "@tarquinen/opencode-dcp" "@mohak34/opencode-notifier" ];
    agents.quick = { model = "opencode/big-pickle"; };
  };
}
