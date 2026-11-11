import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

function findAicontextRoot(start) {
  let dir = resolve(start);
  while (true) {
    if (existsSync(join(dir, "aicontext.yaml")) && existsSync(join(dir, ".opencode", "opencode.json"))) return dir;
    const parent = dirname(dir);
    if (parent === dir) return undefined;
    dir = parent;
  }
}

function envRefs(value) {
  if (typeof value !== "string") throw new Error("expected string");
  if (/\{file:/.test(value)) throw new Error("file substitutions are unsupported");
  return value.replace(/\{env:([A-Za-z_][A-Za-z0-9_]*)\}/g, "${$1}");
}

function mapValues(values = {}) {
  return Object.fromEntries(Object.entries(values).map(([key, value]) => [key, envRefs(value)]));
}

function convert(server) {
  const common = { exposure: "codemode", description: "AIContext workspace MCP server" };
  if (server.type === "remote") return { ...common, url: envRefs(server.url), headers: mapValues(server.headers) };
  if (server.type === "local" && Array.isArray(server.command) && server.command.length > 0) {
    const [command, ...args] = server.command.map(envRefs);
    return { ...common, command, args, env: mapValues(server.environment) };
  }
  throw new Error(`unsupported server type '${server.type}'`);
}

export default function (pi) {
  const root = findAicontextRoot(process.cwd());
  if (!root) return;

  let servers;
  try {
    servers = JSON.parse(readFileSync(join(root, ".opencode", "opencode.json"), "utf8"))?.mcp?.servers ?? {};
  } catch (error) {
    console.error(`AIContext MCP config could not be read: ${error.message}`);
    return;
  }

  for (const [name, server] of Object.entries(servers)) {
    if (server?.disabled === true || server?.enabled === false) continue;
    try {
      pi.registerMcpServer(name, convert(server));
    } catch (error) {
      // Never print config values: they may contain credentials.
      console.error(`AIContext MCP '${name}' skipped: ${error.message}`);
    }
  }
}
