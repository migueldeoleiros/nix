let
  commonSkills = [
    "browser-devtools-investigation" "code-review" "codegraph-context7" "debugging"
    "engram-memory" "exploration-deep-dive" "frontend-visual-verification" "java"
    "orca-workspace-checkpoints" "plan-review" "pr-review" "react" "skill-maintenance"
    "tech-test-review" "verification"
  ];
  commonRoles = [
    "quick" "assistant" "build" "plan" "investigate" "reviewer" "verifier"
    "spec-writer" "general" "worker" "browser"
  ];
  commonProfile = { skills = commonSkills; roles = commonRoles; roleModels = {}; };
in {
  merlin = commonProfile // {
    # Merlin-only workflows. Tool integrations remain absent until their
    # runtime artifacts and authentication can be made reproducible and safe.
    skills = commonSkills ++ [
      "gitea-ci-investigation" "gitea-issue-triage" "gitea-pr-management"
      "gitea-release-changelog" "sonarqube-review"
    ];
    roles = commonRoles ++ [ "gitea-repo" ];
  };
  personal = commonProfile // {
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
  inditex = commonProfile;
}
