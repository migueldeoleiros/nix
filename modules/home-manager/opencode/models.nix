{
  personal = {
    smallModel = "opencode/big-pickle";
    agents = {
      quick = { model = "opencode/big-pickle"; };
      assistant = { model = "merlin/gpt-6-sol"; variant = "balanced"; };
      build = { model = "merlin/gpt-6-sol"; variant = "balanced"; };
      plan = { model = "merlin/gpt-6-sol"; variant = "balanced"; };
      investigate = { model = "merlin/gpt-5.6-terra"; variant = "fast"; };
      reviewer = { model = "merlin/gpt-6-sol"; variant = "deep"; };
      verifier = { model = "merlin/gpt-5.6-terra"; variant = "fast"; };
      "spec-writer" = { model = "merlin/gpt-5.6-terra"; variant = "fast"; };
      general = { model = "merlin/gpt-5.6-terra"; variant = "fast"; };
      worker = { model = "merlin/gpt-5.6-terra"; variant = "balanced"; };
      browser = { model = "merlin/gpt-5.6-terra"; variant = "fast"; };
      "gitea-repo" = { model = "merlin/gpt-5.6-terra"; variant = "balanced"; };
    };
  };

  inditex = { };
}
