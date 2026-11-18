let
  # Pi owns this pin independently of OpenCode's import of the same catalog.
  managedConfig = builtins.fromJSON (builtins.readFile (builtins.fetchurl {
    url = "https://llm.merlinsoftware.es/.well-known/opencode/managed-v1.json";
    sha256 = "1lb2jcvyk3knz6xw56mkss0xsyvks69aq9c3w7hqz8vhwf8xfm3b";
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
        # OpenCode explicitly configures reasoning-effort variants for these
        # two models. Enable Pi thinking so the mirrored role levels take effect.
        reasoning = builtins.elem id [ "gpt-6.2-sol" "gpt-5.6-terra" ];
        # Leave pricing and other models' reasoning at Pi defaults; the managed
        # catalog does not declare them. OpenCode-only options stay omitted.
      }
    ) (builtins.attrNames provider.models);
  };
}
