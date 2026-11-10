import { existsSync, readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, isAbsolute, join, resolve } from "node:path";

// Keep this dispatch table aligned with the pinned CLI's commands/commands.ts.
// Return the insertion point, not shell code; the launcher preserves argv verbatim.
function standalone(args) {
  let index = 0;
  while (args[index]?.startsWith("--print-logs")) index++;
  const command = args[index];
  let insert = index;
  if (["run", "mini", "api", "models", "stats", "reload"].includes(command)) {
    insert = index + 1;
  } else if (["auth", "session"].includes(command)) {
    index++;
    while (args[index]?.startsWith("--print-logs")) index++;
    const supported = command === "auth"
      ? ["list", "login", "logout", "export", "import", "switch"]
      : ["list", "delete", "export", "import"];
    if (!supported.includes(args[index])) return -1;
    insert = index + 1;
  } else if (["upgrade", "update", "uninstall", "acp", "debug", "mcp", "plugin", "service", "pair", "serve"].includes(command)) {
    return -1;
  }

  // Do not mistake flag values (e.g. --prompt '--server') or post-- message
  // tokens for connection flags. Explicit connection choices and help pass through.
  const values = new Set([
    "--session", "-s", "--prompt", "--data", "-d", "--header", "-H", "--param",
    "--format", "--method", "--answer", "--days", "--year", "--project", "--limit",
    "--replay-limit", "--model", "-m", "--agent", "--file", "-f", "--title",
    "--max-count", "-n", "--directory",
  ]);
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--") break;
    if (["--help", "-h", "--version", "-V", "--server", "--standalone", "--no-standalone"].includes(arg)
      || arg.startsWith("--server=") || arg.startsWith("--standalone=")) return -1;
    if (values.has(arg)) i++;
  }
  return insert;
}

function readConfig(path, parserPath) {
  // Same parser/options as the pinned CLI's config/config.ts parseRecord.
  const { parse } = createRequire(import.meta.url)(parserPath);
  let config;
  try {
    const errors = [];
    config = parse(readFileSync(path, "utf8"), errors, { allowTrailingComma: true });
    if (errors.length) throw new Error("Invalid JSONC");
  } catch (error) {
    if (error.code !== "ENOENT") throw new Error(`Cannot read valid JSONC from ${path}; fix the file before launching.`);
    config = {};
  }
  if (!config || typeof config !== "object" || Array.isArray(config)) {
    throw new Error(`Expected a JSON object in ${path}.`);
  }
  return config;
}

function plugins(path, parserPath, orcaPlugin) {
  const config = readConfig(path, parserPath);
  if (config.plugins !== undefined && !Array.isArray(config.plugins)) {
    throw new Error(`Expected a plugins array in ${path}.`);
  }
  // Arrays replace rather than merge in OPENCODE_CLI_CONFIG_CONTENT. Preserve
  // every existing directive/package; only supply the default when absent.
  const directives = [...(config.plugins ?? ["*"]), "-opencode.notifications"];
  // Orca installs its pane-local V2 hook outside our isolated profile dirs.
  // Load the TUI directory, not the server hook or tui.js file. Put it first so
  // client-owned disable directives still win. Outside Orca, leave profiles alone.
  if (process.env.ORCA_OPENCODE_AGENT === "opencode2" && process.env.ORCA_PANE_KEY
    && orcaPlugin && existsSync(`${orcaPlugin}/tui.js`)) {
    directives.unshift(orcaPlugin);
  }
  return { plugins: directives };
}

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function merge(left, right) {
  return Object.fromEntries([...new Set([...Object.keys(left), ...Object.keys(right)])].map((key) => [
    key,
    !Object.hasOwn(right, key) ? left[key]
      : isRecord(left[key]) && isRecord(right[key]) ? merge(left[key], right[key]) : right[key],
  ]));
}

// Inline config resolves file references against the profile directory. Keep
// references relative to the corporate file working without reading their values.
function rebaseFiles(value, directory) {
  if (typeof value === "string") {
    return value.replace(/\{file:([^}]+)\}/g, (_, path) =>
      `{file:${isAbsolute(path) || path.startsWith("~/") ? path : resolve(directory, path)}}`);
  }
  if (Array.isArray(value)) return value.map((item) => rebaseFiles(item, directory));
  if (isRecord(value)) return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, rebaseFiles(item, directory)]));
  return value;
}

function providers(directory, parserPath) {
  let result = {};
  for (const name of ["opencode.json", "opencode.jsonc"]) {
    const path = join(directory, name);
    const config = readConfig(path, parserPath);
    const selected = {};
    // V2 accepts complete V1 provider entries alongside native V2 entries.
    // Never import global model selection, MCPs, agents, plugins, permissions,
    // or commands here; model defaults belong to the Nix/project config.
    for (const key of ["provider", "providers"]) {
      if (config[key] === undefined) continue;
      if (!isRecord(config[key])) throw new Error(`Expected a ${key} object in ${path}.`);
      selected[key] = rebaseFiles(config[key], dirname(path));
    }
    result = merge(result, selected);
  }
  return result;
}

try {
  const [mode, ...args] = process.argv.slice(2);
  if (mode === "plugins") process.stdout.write(JSON.stringify(plugins(args[0], args[1], args[2])));
  else if (mode === "providers") process.stdout.write(JSON.stringify(providers(args[0], args[1])));
  else if (mode === "standalone") process.stdout.write(String(standalone(args)));
  else throw new Error("Unknown OpenCode launcher helper mode.");
} catch (error) {
  console.error(`OpenCode launcher: ${error.message}`);
  process.exitCode = 1;
}
