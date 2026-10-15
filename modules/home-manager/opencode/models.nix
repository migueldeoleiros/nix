{
  merlin = {
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
    agents.quick = { model = "opencode/big-pickle"; };
  };
}
