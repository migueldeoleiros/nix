import { execFileSync } from "node:child_process";
import { readFile, writeFile, rename, unlink } from "node:fs/promises";
import { join } from "node:path";
import { randomUUID } from "node:crypto";
import { getBuiltinModels, getBuiltinProviders } from "@earendil-works/pi-ai/providers/all";
import { anthropicMessagesApi, openAICompletionsApi, openAIResponsesApi } from "@earendil-works/pi-ai/compat";

const API = "miguelllm-proxy";
const PLACEHOLDER = "https://proxy.invalid";
const TTL = 5 * 60 * 1000;
const ROUTES = {
  "anthropic-messages": "/v1/messages",
  "openai-completions": "/v1/chat/completions",
  "openai-responses": "/v1/responses",
};

function readSecret(name) {
  try {
    return execFileSync("@AGENT_SECRETS@", ["read", "--trim-eol", name], {
      encoding: "utf8", timeout: 5000, maxBuffer: 16384, stdio: ["ignore", "pipe", "ignore"],
    });
  } catch {
    throw new Error("miguelllm: keyring secret unavailable; unlock keyring and reload");
  }
}

export function validateOrigin(value) {
  try {
    const url = new URL(value);
    if (/\s/.test(value) || url.protocol !== "https:" || url.username || url.password
      || url.pathname !== "/" || url.search || url.hash) throw new Error();
    return url.origin;
  } catch {
    throw new Error("miguelllm: invalid proxy URL in keyring (HTTPS origin required)");
  }
}

// Only the SDK beta marker is removed. All other query/target changes fail closed.
export function proxyFetch(origin, path, fetchImpl = globalThis.fetch) {
  return (input, init) => {
    const url = new URL(input instanceof Request ? input.url : input);
    if (url.origin !== origin || url.pathname !== path || url.username || url.password || url.hash
      || (url.search !== "" && !(path === ROUTES["anthropic-messages"] && url.search === "?beta=true"))) {
      throw new Error("miguelllm: unexpected request target (not sent)");
    }
    url.search = "";
    return fetchImpl(input instanceof Request ? new Request(url, input) : url, { ...init, redirect: "error" });
  };
}

export function catalogModels() {
  const catalog = new Map();
  const providers = [...new Set(["anthropic", "openai", ...getBuiltinProviders()])];
  for (const provider of providers) {
    for (const model of getBuiltinModels(provider)) {
      if (ROUTES[model.api] && !catalog.has(model.id)) catalog.set(model.id, model);
    }
  }
  return catalog;
}

export function validateIds(ids) {
  if (!Array.isArray(ids) || ids.length > 2000
    || ids.some(id => typeof id !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._:/-]{0,199}$/.test(id))) {
    throw new Error("miguelllm: invalid model discovery response");
  }
  return [...new Set(ids)];
}

export function projectModels(ids, catalog) {
  return validateIds(ids).flatMap(id => {
    const model = catalog.get(id);
    // An ID alone cannot tell us context limits, reasoning or transport. Do not invent metadata.
    if (!model) return [];
    const compat = { ...model.compat };
    // Keep unverified mid-conversation extensions and 1M/cache-warming betas disabled.
    for (const key of ["supportsMidConvoEffort", "supportsMidConvoSystemMessages", "supportsMidConvoToolChanges", "supportsMidConvoToolAdditions"]) delete compat[key];
    return [{
      id, name: `${model.name} (miguelllm)`, api: API,
      reasoning: model.reasoning, thinkingLevelMap: model.thinkingLevelMap,
      input: model.input, inputLimits: model.inputLimits,
      contextWindow: Math.min(model.contextWindow, 200000), maxTokens: Math.min(model.maxTokens, 64000),
      compat,
      // Subscription/proxy billing is not the upstream API's token price.
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    }];
  });
}

export async function discoverIds(origin, key, signal, fetchImpl = globalThis.fetch) {
  try {
    const response = await fetchImpl(`${origin}/v1/models`, {
      headers: { Authorization: `Bearer ${key}` }, redirect: "error",
      signal: signal ? AbortSignal.any([signal, AbortSignal.timeout(15000)]) : AbortSignal.timeout(15000),
    });
    if (!response.ok) throw new Error();
    const body = await response.json();
    if (!Array.isArray(body.data)) throw new Error();
    return validateIds(body.data.map(model => model.id));
  } catch {
    // Never include origin, headers, response bodies or underlying fetch errors.
    throw new Error("miguelllm: model discovery failed; check proxy/keyring connectivity");
  }
}

export default async function (pi) {
  const catalog = catalogModels();
  const cachePath = process.env.PI_CODING_AGENT_DIR && join(process.env.PI_CODING_AGENT_DIR, "miguelllm-models.json");
  let cached, origin, warning;
  const getOrigin = () => origin ??= validateOrigin(readSecret("miguelllm-url"));
  if (cachePath) {
    try {
      const data = JSON.parse(await readFile(cachePath, "utf8"));
      if (data.version === 1 && Number.isFinite(data.fetchedAt) && data.fetchedAt <= Date.now()) {
        cached = { ids: validateIds(data.ids), fetchedAt: data.fetchedAt };
      }
    } catch { /* Missing/corrupt cache is not an authentication fallback. */ }
  }
  async function refresh({ allowNetwork = true, force = false, signal } = {}) {
    if (!allowNetwork || (!force && cached && Date.now() - cached.fetchedAt < TTL)) {
      return projectModels(cached?.ids ?? [], catalog);
    }
    const ids = await discoverIds(getOrigin(), readSecret("miguelllm"), signal);
    cached = { ids, fetchedAt: Date.now() };
    if (cachePath) {
      const temporary = `${cachePath}.${randomUUID()}.tmp`;
      try {
        // Persist only IDs/time, never the origin, credential or response payload.
        await writeFile(temporary, JSON.stringify({ version: 1, ...cached }), { mode: 0o600, flag: "wx" });
        await rename(temporary, cachePath);
      } catch { /* Discovery still works with an unwritable cache. */ }
      finally { await unlink(temporary).catch(() => {}); }
    }
    return projectModels(ids, catalog);
  }
  let models;
  try {
    models = await refresh({ allowNetwork: process.env.PI_OFFLINE !== "1" });
  } catch {
    models = projectModels(cached?.ids ?? [], catalog);
    warning = "miguelllm: discovery unavailable; using cached models (if any). Unlock/check keyring and refresh.";
  }
  pi.registerProvider("miguelllm", {
    name: "Miguel LLM", baseUrl: PLACEHOLDER, api: API,
    apiKey: "!@AGENT_SECRETS@ read --trim-eol miguelllm", authHeader: true,
    models, refreshModels: refresh,
    streamSimple: (model, context, options) => {
      const native = catalog.get(model.id);
      if (!native) throw new Error("miguelllm: model has no supported catalog transport");
      const origin = getOrigin();
      const apis = { "anthropic-messages": anthropicMessagesApi, "openai-completions": openAICompletionsApi, "openai-responses": openAIResponsesApi };
      return apis[native.api]().streamSimple(
        { ...model, api: native.api, baseUrl: origin + (native.api === "anthropic-messages" ? "" : "/v1") }, context,
        { ...options, fetch: proxyFetch(origin, ROUTES[native.api], options?.fetch) },
      );
    },
  });
  pi.registerCommand("miguelllm-refresh", {
    description: "Refresh the proxy model list from the server",
    handler: async (_args, ctx) => {
      const result = await ctx.modelRegistry.refresh({ providers: ["miguelllm"], allowNetwork: true, force: true });
      ctx.ui.notify(result.errors.size ? "miguelllm: discovery refresh failed; previous list retained" : "miguelllm: model list refreshed", result.errors.size ? "warning" : "info");
    },
  });
  if (warning) pi.on("session_start", (_event, ctx) => ctx.ui.notify(warning, "warning"));
}
