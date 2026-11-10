// Run with OPENCODE_TEST_JSONC_PARSER pointing to the launcher's pinned parser.
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { afterEach, beforeEach, test } from "node:test";

const helper = new URL("../launcher-helper.mjs", import.meta.url);
const parser = process.env.OPENCODE_TEST_JSONC_PARSER;
assert.ok(parser, "Set OPENCODE_TEST_JSONC_PARSER to the launcher's jsonc-parser directory");
let root, cli, hook, env;

beforeEach(() => {
  mkdirSync("/tmp/opencode", { recursive: true });
  root = mkdtempSync("/tmp/opencode/test-launcher-helper-");
  cli = join(root, "cli.json");
  hook = join(root, "orca-opencode2-status-tui");
  mkdirSync(hook);
  writeFileSync(join(hook, "tui.js"), "export default {};");
  env = { ...process.env };
  for (const key of Object.keys(env)) {
    if (key.startsWith("ORCA_")) delete env[key];
  }
});
afterEach(() => rmSync(root, { recursive: true, force: true }));

function run(...args) {
  return spawnSync(process.execPath, [helper.pathname, ...args], { env, encoding: "utf8" });
}

function plugins() {
  const result = run("plugins", cli, parser, hook);
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(result.stdout).plugins;
}

function inOrca() {
  env.ORCA_OPENCODE_AGENT = "opencode2";
  env.ORCA_PANE_KEY = "test-tab:test-pane";
}

test("outside Orca preserves default plugins without importing the hook", () => {
  assert.deepEqual(plugins(), ["*", "-opencode.notifications"]);
});

test("Orca V2 adds the installed TUI directory, not its entry file", () => {
  inOrca();
  assert.deepEqual(plugins(), [hook, "*", "-opencode.notifications"]);
});

for (const [name, agent, pane] of [
  ["missing agent", undefined, "test-pane"],
  ["legacy agent", "opencode", "test-pane"],
  ["missing pane", "opencode2", undefined],
  ["empty pane", "opencode2", ""],
]) {
  test(`${name} does not import the hook`, () => {
    if (agent !== undefined) env.ORCA_OPENCODE_AGENT = agent;
    if (pane !== undefined) env.ORCA_PANE_KEY = pane;
    assert.deepEqual(plugins(), ["*", "-opencode.notifications"]);
  });
}

test("missing hook directory or entry does not prevent launch", () => {
  inOrca();
  rmSync(join(hook, "tui.js"));
  assert.deepEqual(plugins(), ["*", "-opencode.notifications"]);
  rmSync(hook, { recursive: true });
  assert.deepEqual(plugins(), ["*", "-opencode.notifications"]);
});

test("JSONC directives and options retain order after the hook, including opt-outs", () => {
  inOrca();
  const directives = ["*", "-orca-opencode2-status", "-orca-*", { package: "example", options: { enabled: true } }];
  writeFileSync(cli, `// client-owned preferences\n{"plugins": ${JSON.stringify(directives)},}`);
  assert.deepEqual(plugins(), [hook, ...directives, "-opencode.notifications"]);
});

test("an explicitly empty plugin list does not enable the default wildcard", () => {
  writeFileSync(cli, '{"plugins": []}');
  assert.deepEqual(plugins(), ["-opencode.notifications"]);
  inOrca();
  assert.deepEqual(plugins(), [hook, "-opencode.notifications"]);
});

for (const invalid of ["{", "null", "[]", '{"plugins": "*"}']) {
  test(`invalid config fails closed: ${invalid}`, () => {
    inOrca();
    writeFileSync(cli, invalid);
    const result = run("plugins", cli, parser, hook);
    assert.equal(result.status, 1);
    assert.equal(result.stdout, "");
    assert.match(result.stderr, /OpenCode launcher:/);
  });
}

test("standalone dispatch is unchanged", () => {
  const result = run("standalone", "run", "hello");
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, "1");
});

function providers(result) {
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(result.stdout);
}

test("corporate provider import is optional when the directory is absent", () => {
  assert.deepEqual(providers(run("providers", ...[join(root, "missing"), parser])), {});
});

test("imports only providers, preserving legacy entries and references but not model selection", () => {
  const directory = root;
  const provider = {
    name: "Corporate", npm: "@ai-sdk/openai-compatible",
    options: { apiKey: "{env:CORPORATE_KEY}", baseURL: "https://example.invalid/v1" },
    models: { reasoner: { name: "Reasoner" } },
  };
  writeFileSync(join(directory, "opencode.jsonc"), JSON.stringify({
    provider: { corporate: provider }, model: "opencode/unwanted",
    mcp: { unwanted: { type: "remote", url: "https://example.invalid/mcp" } },
    agents: { build: { system: "unwanted" } }, plugins: ["unwanted"],
    permissions: [{ action: "*", resource: "*", effect: "allow" }],
    instructions: ["unwanted.md"], commands: { review: { template: "unwanted" } },
    default_agent: "unwanted", skills: ["unwanted"],
  }));
  assert.deepEqual(providers(run("providers", ...[directory, parser])), {
    provider: { corporate: provider },
  });
});

test("supports JSONC, native providers, and jsonc precedence over json", () => {
  const directory = root;
  writeFileSync(join(directory, "opencode.json"), JSON.stringify({
    providers: { corporate: { name: "Old", settings: { baseURL: "https://example.invalid", apiKey: "{env:KEY}" } } },
    model: "corporate/old",
  }));
  writeFileSync(join(directory, "opencode.jsonc"), `{
    // A native V2 provider overlay.
    "providers": { "corporate": { "name": "New", }, },
    "model": "corporate/new",
  }`);
  assert.deepEqual(providers(run("providers", ...[directory, parser])), {
    providers: { corporate: { name: "New", settings: { baseURL: "https://example.invalid", apiKey: "{env:KEY}" } } },
  });
});

test("rebases relative file references without reading secrets or expanding environment references", () => {
  const directory = root;
  writeFileSync(join(directory, "opencode.json"), JSON.stringify({
    providers: { corporate: {
      settings: { apiKey: "{file:keys/nonexistent}" },
      headers: { Authorization: "Bearer {file:../outside.key}", Home: "{file:~/keys/key}", Absolute: "{file:/keys/key}" },
      models: { example: { settings: { values: ["{env:KEY}", "{file:./another.key}"] } } },
    } },
  }));
  const config = providers(run("providers", ...[directory, parser])).providers.corporate;
  assert.equal(config.settings.apiKey, `{file:${directory}/keys/nonexistent}`);
  assert.equal(config.headers.Authorization, `Bearer {file:${join(directory, "../outside.key")}}`);
  assert.equal(config.headers.Home, "{file:~/keys/key}");
  assert.equal(config.headers.Absolute, "{file:/keys/key}");
  assert.deepEqual(config.models.example.settings.values, ["{env:KEY}", `{file:${directory}/another.key}`]);
});

test("invalid corporate config fails closed without printing its contents", () => {
  const directory = root;
  for (const content of ["{ secret-value", "[]", '{"providers": []}', '{"provider": null}']) {
    writeFileSync(join(directory, "opencode.jsonc"), content);
    const result = run("providers", ...[directory, parser]);
    assert.equal(result.status, 1);
    assert.equal(result.stdout, "");
    assert.doesNotMatch(result.stderr, /secret-value/);
  }
});
