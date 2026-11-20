{ lib, hrMerlinContextEnabled }:

let
  commonAgents = [
    "quick" "assistant" "build" "plan" "investigate" "reviewer" "verifier"
    "spec-writer" "general" "worker" "browser"
  ];
  commonCommands = [ "debug" "pr-review" "review" "tech-test-review" "verify" ];
  commonSkills = [
    "browser-devtools-investigation" "code-review" "codegraph-context7" "credential-handling" "debugging"
    "engram-memory" "exploration-deep-dive" "frontend-visual-verification" "grilling" "java"
    "orca-workspace-checkpoints" "plan-review" "pr-review" "react" "skill-maintenance" "tech-test-review" "verification"
  ];
  # V1-only vibeguard is disabled; automatic secret redaction is unavailable.
  commonPlugins = [ "@tarquinen/opencode-dcp@3.2.0" "@mohak34/opencode-notifier@1.0.0" ];
in {
  merlin = {
    gitea = {
      url = "https://gitea.merlinsoftware.es";
      permissions = [ { action = "gitea_*"; resource = "*"; effect = "allow"; } ];
    };
    managedConfig = builtins.fromJSON (builtins.readFile (builtins.fetchurl {
      url = "https://llm.merlinsoftware.es/.well-known/opencode/managed-v1.json";
      sha256 = "1mh4ijb5d9n0q8115plkm92zj3bxbzib0izl4x34xy5bxsr4j5wi";
    }));
    enabledAgents = commonAgents ++ [ "gitea-repo" ];
    commands = commonCommands;
    skills = commonSkills ++ [
      "gitea-ci-investigation" "gitea-issue-triage" "gitea-pr-management"
      "gitea-release-changelog" "sonarqube-review"
    ];
    externalModels = true; # Agents inherit the managed default rather than custom model routes.
    mcp = [ "gitea" "sonarqube" "trivy" "engram" "codegraph" "context7" ]
      ++ lib.optional hrMerlinContextEnabled "hr-merlin-context";
    plugins = commonPlugins;
  };

  inditex = {
    enabledAgents = commonAgents;
    commands = commonCommands;
    skills = commonSkills;
    # Explicit Copilot routes; corporate provider definitions still load at runtime.
    externalModels = false;
    mcp = [ "engram" "codegraph" "context7" ];
    plugins = commonPlugins;
    model = "github-copilot/gpt-6.1-sol";
    smallModel = "github-copilot/gpt-6-luna#low";
    agents = {
      quick = { model = "github-copilot/claude-haiku-5.5#low"; };
      assistant = { model = "github-copilot/gpt-6.1-sol#medium"; };
      build = { model = "github-copilot/claude-opus-5.5#low"; };
      plan = { model = "github-copilot/gpt-6.1-sol#medium"; };
      investigate = { model = "github-copilot/claude-haiku-5.5#low"; };
      reviewer = { model = "github-copilot/claude-sonnet-5.5#medium"; };
      verifier = { model = "github-copilot/gpt-5.6-terra#low"; };
      "spec-writer" = { model = "github-copilot/gpt-6-luna#low"; };
      general = { model = "github-copilot/claude-haiku-5.5#low"; };
      # Keep delegated implementation on Sol so Sonnet reviews another model's work.
      worker = { model = "github-copilot/gpt-6.1-sol#medium"; };
      browser = { model = "github-copilot/gpt-5.6-terra#low"; };
    };
  };
}
