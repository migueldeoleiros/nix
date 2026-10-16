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
  # V1-only vibeguard is disabled; automatic secret redaction is unavailable.
  commonPlugins = [ "@tarquinen/opencode-dcp@3.2.0" "@mohak34/opencode-notifier@1.0.0" ];
  managedConfig = builtins.fromJSON (builtins.readFile (builtins.fetchurl {
    url = "https://llm.merlinsoftware.es/.well-known/opencode/managed-v1.json";
    sha256 = "1bd5hclcaz3lm8k68h6snlf50fp5gjlqqn2i598gp0wanqgyzq6s";
  }));
  managedProvider = managedConfig.provider.merlin;
  modelVariants = {
    "gpt-6.1-sol" = {
      settings = { reasoningEffort = "medium"; };
      variants = [
        { id = "balanced"; settings = { reasoningEffort = "medium"; }; }
        { id = "deep"; settings = { reasoningEffort = "high"; textVerbosity = "medium"; }; }
      ];
    };
    "gpt-5.6-terra" = {
      settings = { reasoningEffort = "medium"; };
      variants = [
        { id = "fast"; settings = { reasoningEffort = "low"; }; }
        { id = "balanced"; settings = { reasoningEffort = "medium"; }; }
        { id = "deep"; settings = { reasoningEffort = "high"; textVerbosity = "medium"; }; }
      ];
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
    plugins = commonPlugins;
    # Convert the complete fixed-hash V1 entry; do not mix nested V1/V2 fields.
    providers.merlin = {
      name = managedProvider.name;
      package = "aisdk:${managedProvider.npm}";
      settings.baseURL = managedProvider.options.baseURL;
      headers = managedProvider.options.headers;
      models = lib.mapAttrs (modelName: modelDef: {
        inherit (modelDef) name limit;
        capabilities = modelDef.modalities;
        # V1 attachment has no native equivalent; input modalities are retained.
        settings = modelDef.options;
      } // (modelVariants.${modelName} or {})) managedProvider.models;
    };
    smallModel = "merlin/gpt-6-luna";
    agents = {
      quick = { model = "opencode/big-pickle"; };
      assistant = { model = "merlin/gpt-6.1-sol#balanced"; };
      build = { model = "merlin/gpt-6.1-sol#balanced"; };
      plan = { model = "merlin/gpt-6.1-sol#balanced"; };
      investigate = { model = "merlin/gpt-5.6-terra#fast"; };
      reviewer = { model = "merlin/gpt-6.1-sol#deep"; };
      verifier = { model = "merlin/gpt-5.6-terra#fast"; };
      "spec-writer" = { model = "merlin/gpt-5.6-terra#fast"; };
      general = { model = "merlin/gpt-5.6-terra#fast"; };
      worker = { model = "merlin/gpt-5.6-terra#balanced"; };
      browser = { model = "merlin/gpt-5.6-terra#fast"; };
      "gitea-repo" = { model = "merlin/gpt-5.6-terra#balanced"; };
    };
  };

  personal = {
    enabledAgents = commonAgents;
    commands = commonCommands;
    skills = commonSkills;
    externalModels = false;
    mcp = [ "engram" "codegraph" "context7" ];
    plugins = commonPlugins;
    # V2 has no per-model whitelist; the wider Personal picker is intentional.
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
    plugins = commonPlugins;
    agents.quick = { model = "opencode/big-pickle"; };
  };
}
