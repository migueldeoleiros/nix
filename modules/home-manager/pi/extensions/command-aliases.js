import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";

// Pi 1.4 built-ins are dispatched by the interactive editor, not sendUserMessage.
// Keep unsupported built-ins reserved so they can never fall through to the model.
const BUILTINS = new Set([
  "settings", "model", "tree", "thinking", "scoped-models", "export", "import",
  "share", "bug", "copy", "name", "session", "changelog", "hotkeys", "fork",
  "clone", "trust", "login", "logout", "new", "compact", "resume", "reload",
  "quit", "debug", "arminsayshi", "dementedelves", "help",
]);
const SUPPORTED = new Set(["quit", "new", "reload", "compact", "model", "resume", "thinking", "name"]);
const NAME = /^[a-zA-Z0-9][a-zA-Z0-9:_-]*$/;

function splitCommand(text) {
  const match = /^\/([^\s]+)(?:\s+([\s\S]*))?$/.exec(text);
  if (!match || !NAME.test(match[1])) throw new Error(`Invalid alias target: ${text}`);
  return { name: match[1], args: match[2] ?? "" };
}

// Flatten chains once; arguments nearest the final target come first.
export function compileAliases(config) {
  if (!config || typeof config !== "object" || Array.isArray(config)) {
    throw new Error("command-aliases.json must contain an object mapping names to /commands.");
  }
  const aliases = new Map(Object.entries(config));
  for (const [name, target] of aliases) {
    if (!NAME.test(name) || BUILTINS.has(name)) throw new Error(`Reserved or invalid alias name: ${name}`);
    if (typeof target !== "string") throw new Error(`Alias /${name} must target a /command string.`);
  }
  function expand(name, visiting = new Set()) {
    if (visiting.has(name)) throw new Error(`Alias cycle involving /${name}`);
    visiting.add(name);
    const target = splitCommand(aliases.get(name).trim());
    if (!aliases.has(target.name)) return target;
    const expanded = expand(target.name, visiting);
    return { name: expanded.name, args: [expanded.args, target.args].filter(Boolean).join(" ") };
  }
  return new Map([...aliases.keys()].map((name) => [name, expand(name)]));
}

async function builtin(pi, ctx, name, args) {
  if (["quit", "new", "reload"].includes(name) && args) {
    throw new Error(`/${name} does not accept arguments.`);
  }
  switch (name) {
    case "quit": return ctx.shutdown();
    case "new": return ctx.newSession();
    case "reload": return ctx.reload();
    case "compact":
      if (!ctx.isIdle()) throw new Error("Wait for the agent to finish before compacting.");
      return ctx.compact({
        customInstructions: args || undefined,
        onError: (error) => ctx.ui.notify(`Compaction failed: ${error.message}`, "error"),
      });
    case "resume":
      // Pi's native session picker is not exposed through the extension API.
      if (!args) throw new Error("This alias requires a session file path. Use /resume for Pi's session picker.");
      return ctx.switchSession(resolve(ctx.cwd, args));
    case "model": {
      const models = ctx.modelRegistry.getAvailable();
      let id = args;
      if (!id) {
        if (!ctx.hasUI) throw new Error("Specify /model provider/model in this mode.");
        id = await ctx.ui.select("Select model", models.map((model) => `${model.provider}/${model.id}`));
        if (!id) return;
      }
      const model = models.find((candidate) => `${candidate.provider}/${candidate.id}` === id);
      if (!model) throw new Error(`Unknown or unavailable model: ${id}. Use provider/model.`);
      if (!(await pi.setModel(model))) throw new Error(`Authentication unavailable for ${id}.`);
      return;
    }
    case "thinking":
      if (!["off", "minimal", "low", "medium", "high", "xhigh"].includes(args)) {
        throw new Error("Specify a thinking level: off, minimal, low, medium, high, xhigh.");
      }
      return pi.setThinkingLevel(args);
    case "name":
      if (!args) throw new Error("Specify a session name.");
      return pi.setSessionName(args);
  }
}

export function registerAliases(pi, aliases, ctx) {
  // Called after all factories have loaded: getCommands is unavailable in factories.
  const commands = pi.getCommands();
  const existing = new Set(commands.map((command) => command.name));
  for (const [name, target] of aliases) {
    if (existing.has(name)) {
      ctx.ui.notify(`Alias /${name} conflicts with an existing command; skipped.`, "error");
      continue;
    }
    if (BUILTINS.has(target.name) ? !SUPPORTED.has(target.name) : !existing.has(target.name)) {
      ctx.ui.notify(`Alias /${name}: unsupported or unknown target /${target.name}; skipped.`, "error");
      continue;
    }
    pi.registerCommand(name, {
      description: `Alias for /${target.name}${target.args ? ` ${target.args}` : ""}`,
      handler: async (args, commandCtx) => {
        try {
          const forwarded = [target.args, args].filter(Boolean).join(" ");
          if (BUILTINS.has(target.name)) return await builtin(pi, commandCtx, target.name, forwarded);
          // Recheck dynamic targets so a missing command never becomes an LLM prompt.
          if (!pi.getCommands().some((command) => command.name === target.name)) {
            throw new Error(`Alias target /${target.name} is no longer available.`);
          }
          pi.sendUserMessage(`/${target.name}${forwarded ? ` ${forwarded}` : ""}`, {
            expandPromptTemplates: true,
            deliverAs: "followUp",
          });
        } catch (error) {
          commandCtx.ui.notify(`Alias /${name}: ${error.message}`, "error");
        }
      },
    });
  }
}

export default async function (pi) {
  const agentDir = process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
  let config;
  try {
    config = JSON.parse(await readFile(join(agentDir, "command-aliases.json"), "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") return;
    throw error;
  }
  const aliases = compileAliases(config);
  let registered = false;
  pi.on("session_start", (_event, ctx) => {
    if (registered) return;
    registerAliases(pi, aliases, ctx);
    registered = true;
  });
}
