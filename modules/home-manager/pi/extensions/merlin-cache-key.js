// Pi's Chat Completions adapter does not send a cache key to custom endpoints
// with normal retention. Merlin needs session affinity without opting into 24h
// retention or changing API protocols.
export default function (pi) {
  pi.on("before_provider_request", (event, ctx) => {
    const model = ctx.model;
    const payload = event.payload;
    if (model?.provider !== "merlin" || model.api !== "openai-completions") return;
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) return;
    if (payload.model !== model.id || payload.prompt_cache_key !== undefined) return;

    const sessionId = ctx.sessionManager.getSessionId();
    if (typeof sessionId !== "string" || !sessionId) return;
    return { ...payload, prompt_cache_key: sessionId.slice(0, 64) };
  });
}
