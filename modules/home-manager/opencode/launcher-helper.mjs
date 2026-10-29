import { existsSync, readFileSync } from "node:fs";
import { createRequire } from "node:module";

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

function plugins(path, parserPath, orcaPlugin) {
  // Same parser/options as the pinned CLI's config/config.ts parseRecord.
  const { parse } = createRequire(import.meta.url)(parserPath);
  let config;
  try {
    const errors = [];
    config = parse(readFileSync(path, "utf8"), errors, { allowTrailingComma: true });
    if (errors.length) throw new Error("Invalid JSONC");
  } catch (error) {
    if (error.code !== "ENOENT") throw new Error(`Cannot read valid JSONC from ${path}; fix cli.json before launching.`);
    config = {};
  }
  if (!config || typeof config !== "object" || Array.isArray(config)) {
    throw new Error(`Expected a JSON object in ${path}.`);
  }
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

try {
  const [mode, ...args] = process.argv.slice(2);
  if (mode === "plugins") process.stdout.write(JSON.stringify(plugins(args[0], args[1], args[2])));
  else if (mode === "standalone") process.stdout.write(String(standalone(args)));
  else throw new Error("Unknown OpenCode launcher helper mode.");
} catch (error) {
  console.error(`OpenCode launcher: ${error.message}`);
  process.exitCode = 1;
}
