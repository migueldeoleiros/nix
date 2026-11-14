import assert from "node:assert/strict";
import { readFile, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import vm from "node:vm";

const source = await readFile(new URL("../extensions/miguelllm.js", import.meta.url), "utf8");
const origin = "https://private-proxy.example";
const metadata = (id, api) => ({ id, api, name: id, input: ["text"], reasoning: true,
  contextWindow: 1000000, maxTokens: 128000, thinkingLevelMap: { medium: "medium" },
  compat: { forceAdaptiveThinking: true, supportsMidConvoSystemMessages: true },
});
const catalog = [metadata("claude-test", "anthropic-messages"), metadata("gpt-test", "openai-responses"), metadata("chat-test", "openai-completions")];

async function load() {
  const state = { lookups: [], calls: [], registrations: [], commands: [], requests: 0, ids: catalog.map(m => m.id) };
  const child = new vm.SyntheticModule(["execFileSync"], function () {
    this.setExport("execFileSync", (_exe, args, options) => {
      assert.equal(options.stdio[2], "ignore");
      state.lookups.push(args.at(-1));
      if (state.locked) throw new Error("SECRET CHILD ERROR");
      return args.at(-1) === "miguelllm-url" ? origin : "dummy-key";
    });
  });
  const models = new vm.SyntheticModule(["getBuiltinModels", "getBuiltinProviders"], function () {
    this.setExport("getBuiltinProviders", () => ["anthropic", "openai"]);
    this.setExport("getBuiltinModels", provider => catalog.filter(m => (provider === "anthropic") === m.id.startsWith("claude")));
  });
  const names = ["anthropicMessagesApi", "openAICompletionsApi", "openAIResponsesApi"];
  const apis = new vm.SyntheticModule(names, function () {
    for (const name of names) this.setExport(name, () => ({ streamSimple: (...args) => { state.calls.push({ name, args }); return "stream"; } }));
  });
  const module = new vm.SourceTextModule(source);
  await module.link(async name => {
    if (name === "node:child_process") return child;
    if (name.endsWith("/providers/all")) return models;
    if (name.endsWith("/compat")) return apis;
    const native = await import(name);
    return new vm.SyntheticModule(Object.keys(native), function () {
      for (const key of Object.keys(native)) this.setExport(key, native[key]);
    });
  });
  await module.evaluate();
  state.api = module.namespace;
  state.pi = {
    registerProvider: (name, config) => state.registrations.push({ name, config }),
    registerCommand: (name, config) => state.commands.push({ name, config }),
    on: () => {},
  };
  state.fetch = async (url, init) => {
    state.requests++;
    assert.equal(url, `${origin}/v1/models`);
    assert.equal(init.headers.Authorization, "Bearer dummy-key");
    assert.equal(init.redirect, "error");
    return new Response(JSON.stringify({ data: state.ids.map(id => ({ id })) }));
  };
  return state;
}

test("URL validation fails closed, including embedded control/whitespace", async () => {
  const { api } = await load();
  assert.equal(api.validateOrigin(origin), origin);
  for (const value of ["http://proxy.example", `${origin}/path`, `${origin}?key=dummy`, `${origin}#x`, "https://user:pass@proxy.example", "https://ho\nst", ` ${origin}`]) {
    assert.throws(() => api.validateOrigin(value), /invalid proxy URL/);
  }
});

test("projects only discovered known IDs; reuses metadata without upstream URL/credentials", async () => {
  const { api } = await load();
  const result = api.projectModels(["claude-test", "unknown", "gpt-test", "claude-test"], api.catalogModels());
  assert.deepEqual(result.map(m => m.id), ["claude-test", "gpt-test"]);
  assert.equal(result[0].compat.forceAdaptiveThinking, true);
  assert.equal(result[0].compat.supportsMidConvoSystemMessages, undefined);
  assert.equal(result[0].contextWindow, 200000);
  assert.equal(result[0].maxTokens, 64000);
  assert.equal(result[0].baseUrl, undefined);
  assert.equal(result[0].api, "miguelllm-proxy");
  assert.throws(() => api.validateIds(["bad\nmodel"]), /invalid model discovery response/);
});

test("strict fetch guard preserves body/headers/abort, forbids redirects and extra queries", async () => {
  const { api } = await load();
  const controller = new AbortController();
  const request = new Request(`${origin}/v1/messages?beta=true`, { method: "POST", body: "body", headers: { authorization: "Bearer dummy" }, signal: controller.signal });
  let calls = 0;
  const fetch = api.proxyFetch(origin, "/v1/messages", async (input, init) => {
    calls++;
    assert.equal(input.url, `${origin}/v1/messages`);
    assert.equal(await input.text(), "body");
    assert.equal(input.headers.get("authorization"), "Bearer dummy");
    assert.equal(init.redirect, "error");
    controller.abort(); assert.equal(input.signal.aborted, true);
  });
  await fetch(request);
  for (const url of ["https://other.example/v1/messages", `${origin}/v1/models`, `${origin}/v1/messages?beta=true&key=dummy`]) assert.throws(() => fetch(url), /unexpected request target/);
  assert.throws(() => api.proxyFetch(origin, "/v1/responses")(`${origin}/v1/responses?beta=true`), /unexpected request target/);
  assert.equal(calls, 1);
});

test("discovery honors cancellation, validates responses and redacts failures", async () => {
  const { api, fetch } = await load();
  assert.deepEqual(await api.discoverIds(origin, "dummy-key", undefined, fetch), catalog.map(m => m.id));
  const controller = new AbortController(); controller.abort();
  await assert.rejects(api.discoverIds(origin, "dummy-key", controller.signal, async (_url, init) => { init.signal.throwIfAborted(); }), /model discovery failed/);
  await assert.rejects(api.discoverIds(origin, "dummy-key", undefined, async () => new Response("private response", { status: 401 })), /model discovery failed/);
  await assert.rejects(api.discoverIds(origin, "dummy-key", undefined, async () => { throw new Error(origin + " dummy-key"); }), error => !error.message.includes(origin) && !error.message.includes("dummy-key"));
});

test("startup discovery, private ID-only cache, offline restore, refresh and all three transports", async () => {
  const state = await load();
  const dir = await mkdtemp(join(tmpdir(), "miguelllm-test-"));
  const previousDir = process.env.PI_CODING_AGENT_DIR, previousOffline = process.env.PI_OFFLINE;
  const previousFetch = globalThis.fetch;
  try {
    process.env.PI_CODING_AGENT_DIR = dir; delete process.env.PI_OFFLINE; globalThis.fetch = state.fetch;
    await state.api.default(state.pi);
    assert.equal(state.requests, 1);
    const { name, config } = state.registrations[0];
    assert.equal(name, "miguelllm"); assert.equal(config.models.length, 3);
    assert.equal(config.baseUrl, "https://proxy.invalid");
    assert.equal(config.apiKey, "!@AGENT_SECRETS@ read --trim-eol miguelllm");
    const cache = await readFile(join(dir, "miguelllm-models.json"), "utf8");
    assert.equal(cache.includes(origin), false); assert.equal(cache.includes("dummy-key"), false);
    for (const model of config.models) assert.equal(config.streamSimple(model, {}, { apiKey: "dummy-key" }), "stream");
    assert.deepEqual(state.calls.map(c => c.name), ["anthropicMessagesApi", "openAIResponsesApi", "openAICompletionsApi"]);
    assert.equal(state.calls[0].args[0].baseUrl, origin);
    assert.equal(state.calls[1].args[0].baseUrl, `${origin}/v1`);
    await config.refreshModels({ allowNetwork: false }); assert.equal(state.requests, 1);
    state.ids = ["gpt-test"];
    const refreshed = await config.refreshModels({ allowNetwork: true, force: true });
    assert.deepEqual(refreshed.map(m => m.id), ["gpt-test"]); assert.equal(state.requests, 2);
    process.env.PI_OFFLINE = "1";
    const offline = await load(); offline.locked = true;
    await offline.api.default(offline.pi);
    assert.deepEqual(offline.registrations[0].config.models.map(m => m.id), ["gpt-test"]);
    assert.deepEqual(offline.lookups, []);
  } finally {
    globalThis.fetch = previousFetch;
    if (previousDir === undefined) delete process.env.PI_CODING_AGENT_DIR; else process.env.PI_CODING_AGENT_DIR = previousDir;
    if (previousOffline === undefined) delete process.env.PI_OFFLINE; else process.env.PI_OFFLINE = previousOffline;
    await rm(dir, { recursive: true, force: true });
  }
});
