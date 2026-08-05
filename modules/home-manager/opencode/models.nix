{
  personal = {
    smallModel = "opencode/big-pickle";
    agents = {
      quick = { model = "opencode/big-pickle"; };
      assistant = { model = "openai/gpt-5.6-sol"; variant = "balanced"; };
      build = { model = "openai/gpt-5.6-sol"; variant = "balanced"; };
      plan = { model = "openai/gpt-5.6-sol"; variant = "balanced"; };
      investigate = { model = "openai/gpt-5.6-terra"; variant = "fast"; };
      reviewer = { model = "openai/gpt-5.6-sol"; variant = "deep"; };
      verifier = { model = "openai/gpt-5.6-terra"; variant = "fast"; };
      "spec-writer" = { model = "openai/gpt-5.6-terra"; variant = "fast"; };
      general = { model = "openai/gpt-5.6-terra"; variant = "fast"; };
      worker = { model = "openai/gpt-5.6-terra"; variant = "balanced"; };
      browser = { model = "openai/gpt-5.6-terra"; variant = "fast"; };
      "gitea-repo" = { model = "openai/gpt-5.6-terra"; variant = "balanced"; };
    };
  };

  inditex = { };
}
