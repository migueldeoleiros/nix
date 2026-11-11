let
  commonSkills = [
    "browser-devtools-investigation" "code-review" "codegraph-context7" "debugging"
    "engram-memory" "exploration-deep-dive" "frontend-visual-verification" "grilling" "java"
    "orca-workspace-checkpoints" "plan-review" "pr-review" "react" "skill-maintenance"
    "tech-test-review" "verification"
  ];
  commonRoles = [
    "quick" "assistant" "build" "plan" "investigate" "reviewer" "verifier"
    "spec-writer" "general" "worker" "browser"
  ];
  commonProfile = {
    skills = commonSkills;
    roles = commonRoles;
    roleModels = {};
    roleColors = {};
  };
in {
  merlin = commonProfile // {
    # Merlin-only workflows. Tool integrations remain absent until their
    # runtime artifacts and authentication can be made reproducible and safe.
    skills = commonSkills ++ [
      "gitea-ci-investigation" "gitea-issue-triage" "gitea-pr-management"
      "gitea-release-changelog" "sonarqube-review"
    ];
    roles = commonRoles ++ [ "gitea-repo" ];
    models = import ./merlin-models.nix;
  };
  personal = commonProfile // {
    roleColors = import ./role-colors.nix;
    roleModels = {
      quick = { provider = "openai-codex"; modelId = "gpt-6-luna"; thinkingLevel = "low"; };
      assistant = { provider = "openai-codex"; modelId = "gpt-6.1-sol"; thinkingLevel = "low"; };
      build = { provider = "openai-codex"; modelId = "gpt-6.1-sol"; thinkingLevel = "medium"; };
      plan = { provider = "openai-codex"; modelId = "gpt-6.1-sol"; thinkingLevel = "medium"; };
      investigate = { provider = "openai-codex"; modelId = "gpt-6-luna"; thinkingLevel = "low"; };
      reviewer = { provider = "openai-codex"; modelId = "gpt-6.1-sol"; thinkingLevel = "high"; };
      verifier = { provider = "openai-codex"; modelId = "gpt-6-luna"; thinkingLevel = "low"; };
      "spec-writer" = { provider = "openai-codex"; modelId = "gpt-6-luna"; thinkingLevel = "medium"; };
      general = { provider = "openai-codex"; modelId = "gpt-6-luna"; thinkingLevel = "medium"; };
      worker = { provider = "openai-codex"; modelId = "gpt-6-luna"; thinkingLevel = "high"; };
      browser = { provider = "openai-codex"; modelId = "gpt-6-luna"; thinkingLevel = "low"; };
    };
  };
  inditex = commonProfile // {
    aicontext = true;
    # Match the owned-agent routes in the corresponding OpenCode profile.
    roleModels = {
      quick = { provider = "github-copilot"; modelId = "claude-haiku-5.5"; thinkingLevel = "low"; };
      assistant = { provider = "github-copilot"; modelId = "gpt-6.1-sol"; thinkingLevel = "medium"; };
      build = { provider = "github-copilot"; modelId = "claude-opus-5.5"; thinkingLevel = "low"; };
      plan = { provider = "github-copilot"; modelId = "gpt-6.1-sol"; thinkingLevel = "medium"; };
      investigate = { provider = "github-copilot"; modelId = "claude-haiku-5.5"; thinkingLevel = "low"; };
      reviewer = { provider = "github-copilot"; modelId = "claude-sonnet-5.5"; thinkingLevel = "medium"; };
      verifier = { provider = "github-copilot"; modelId = "gpt-5.6-terra"; thinkingLevel = "low"; };
      "spec-writer" = { provider = "github-copilot"; modelId = "gpt-6-luna"; thinkingLevel = "low"; };
      general = { provider = "github-copilot"; modelId = "claude-haiku-5.5"; thinkingLevel = "low"; };
      # Keep implementation on Sol and independent review on Sonnet.
      worker = { provider = "github-copilot"; modelId = "gpt-6.1-sol"; thinkingLevel = "medium"; };
      browser = { provider = "github-copilot"; modelId = "gpt-5.6-terra"; thinkingLevel = "low"; };
    };
  };
}
