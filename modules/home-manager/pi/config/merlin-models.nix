let
  # Pi owns this pin independently of OpenCode's import of the same catalog.
  managedConfig = builtins.fromJSON (builtins.readFile (builtins.fetchurl {
    url = "https://llm.merlinsoftware.es/.well-known/opencode/managed-v1.json";
    sha256 = "1bd5hclcaz3lm8k68h6snlf50fp5gjlqqn2i598gp0wanqgyzq6s";
  }));
  provider = managedConfig.provider.merlin;
in {
  providers.merlin = {
    inherit (provider) name;
    baseUrl = provider.options.baseURL;
    api = "openai-completions";
    apiKey = "$MERLIN_API_KEY";
    authHeader = true;
    headers = provider.options.headers;
    models = map (id:
      let model = provider.models.${id};
      in {
        inherit id;
        inherit (model) name;
        input = model.modalities.input;
        contextWindow = model.limit.context;
        maxTokens = model.limit.output;
        # The catalog declares neither reasoning support nor pricing. Leave
        # Pi's defaults; do not infer thinking levels from model aliases.
        # OpenCode attachment/options/variants are intentionally not imported.
      }
    ) (builtins.attrNames provider.models);
  };
}
