import { readdir, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { parseColor } from "@earendil-works/pi-tui";

const ENTRY_TYPE = "nix-primary-role";
const DEFAULT_ROLE = "assistant";

// Standalone defaults; role-colors.json may override any role with a hex color
// or one of these preset names. Nix only supplies personal hex overrides.
const PALETTE = Object.freeze({
  blue: "#4fc3f7",
  green: "#9ccc65",
  orange: "#ffb74d",
  purple: "#ba68c8",
  red: "#e57373",
  teal: "#4db6ac",
  gray: "#90a4ae",
  yellow: "#ffd54f",
});
const DEFAULT_ROLE_COLORS = Object.freeze({
  quick: PALETTE.green,
  assistant: PALETTE.blue,
  build: PALETTE.orange,
  plan: PALETTE.purple,
  investigate: "#64b5f6",
  reviewer: PALETTE.red,
  verifier: PALETTE.teal,
  "spec-writer": PALETTE.purple,
  general: PALETTE.gray,
  worker: PALETTE.yellow,
  browser: "#42a5f5",
  "gitea-repo": "#81c784",
  email: "#26a69a",
});

function findAicontextAgentsDir(start) {
  let dir = resolve(start);
  while (true) {
    const agents = join(dir, ".opencode", "agents");
    if (existsSync(join(dir, "aicontext.yaml")) && existsSync(agents)) return agents;
    const parent = dirname(dir);
    if (parent === dir) return undefined;
    dir = parent;
  }
}

function frontmatter(source) {
  return source.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
}

function stripFrontmatter(source) {
  const match = frontmatter(source);
  return match ? source.slice(match[0].length).trimStart() : source;
}

function frontmatterValue(source, key) {
  const match = frontmatter(source ?? "");
  const line = match?.[1].split(/\r?\n/).find((candidate) => candidate.startsWith(`${key}:`));
  return line?.slice(key.length + 1).trim().replace(/^(['"])(.*)\1$/, "$2");
}

export default function (pi) {
  // Child agents inherit this extension but must retain their own prompt/model.
  // Return before registering hooks; do not alter any other extensions' state.
  if (
    process.env.PI_SUBAGENT_CHILD === "1" ||
    Boolean(process.env.PI_SUBAGENT_AGENT || process.env.PI_SUBAGENT_SESSION || process.env.PI_SUBAGENT_ID)
  ) return;

  const agentDir = process.env.PI_CODING_AGENT_DIR;
  const aicontextAgentsDir = agentDir && existsSync(join(agentDir, "extensions", "aicontext-mcp.js")) ? findAicontextAgentsDir(process.cwd()) : undefined;
  let role = DEFAULT_ROLE;
  let roleCommands = Promise.resolve();

  async function aicontextRoles() {
    if (!aicontextAgentsDir) return [];
    return (await readdir(aicontextAgentsDir, { withFileTypes: true }))
      .filter((entry) => (entry.isFile() || entry.isSymbolicLink()) && entry.name.endsWith(".md"))
      .map((entry) => entry.name.slice(0, -3))
      .sort();
  }

  async function availableRoles() {
    const roles = JSON.parse(await readFile(join(agentDir, "roles.json"), "utf8"));
    return [...roles, ...(await aicontextRoles()).filter((name) => !roles.includes(name))];
  }

  async function aicontextRoleFile(name) {
    if (!aicontextAgentsDir || !(await aicontextRoles()).includes(name)) return undefined;
    return readFile(join(aicontextAgentsDir, `${name}.md`), "utf8");
  }

  async function rolePrompt(name) {
    try {
      return await readFile(join(agentDir, "prompts", `${name}.md`), "utf8");
    } catch (error) {
      const source = await aicontextRoleFile(name);
      if (source === undefined) throw error;
      return stripFrontmatter(source);
    }
  }

  async function updateRoleStatus(ctx) {
    let colors = {};
    try {
      colors = JSON.parse(await readFile(join(agentDir, "role-colors.json"), "utf8"));
    } catch (error) {
      if (error.code !== "ENOENT") {
        ctx.ui.notify(`Could not load role colors (${error.message}); using the default color.`, "error");
      }
    }
    // Concrete colors remain valid across theme changes; Pi handles terminal color depth.
    const configured = colors?.[role];
    const preset = Object.hasOwn(PALETTE, configured) ? PALETTE[configured] : undefined;
    const color = preset ?? (typeof configured === "string" && /^#[0-9a-fA-F]{6}$/.test(configured)
      ? configured : DEFAULT_ROLE_COLORS[role] ?? PALETTE.blue);
    ctx.ui.setStatus("primary-role", `role: ${ctx.ui.theme.style(role, { fg: parseColor(color), bold: true })}`);
  }

  async function roleModels() {
    let models;
    try {
      models = JSON.parse(await readFile(join(agentDir, "role-models.json"), "utf8"));
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
      models = {};
    }
    for (const name of await aicontextRoles()) {
      if (models[name]) continue;
      const model = frontmatterValue(await aicontextRoleFile(name), "model");
      const separator = model?.indexOf("/") ?? -1;
      if (separator > 0) models[name] = { provider: model.slice(0, separator), modelId: model.slice(separator + 1) };
    }
    return models;
  }

  async function applyRoleModel(targetRole, ctx, { notifyUnmapped = false } = {}) {
    try {
      const mapping = (await roleModels())[targetRole];
      if (!mapping) {
        if (notifyUnmapped) ctx.ui.notify(`No model mapped for role '${targetRole}'; keeping the current Pi model.`, "info");
        return false;
      }
      const models = ctx.modelRegistry.getAvailable();
      const model = models.find((candidate) => candidate.provider === mapping.provider && candidate.id === mapping.modelId);
      if (!model) {
        ctx.ui.notify(`Model ${mapping.provider}/${mapping.modelId} configured for role '${targetRole}' is unavailable; keeping the current Pi model.`, "error");
        return false;
      }
      const selected = await pi.setModel(model);
      if (selected === false) {
        ctx.ui.notify(`Could not switch to ${mapping.provider}/${mapping.modelId} for role '${targetRole}'; keeping the current Pi model (Pi rejected model selection).`, "error");
        return false;
      }
      if (mapping.thinkingLevel) pi.setThinkingLevel(mapping.thinkingLevel);
      return true;
    } catch (error) {
      ctx.ui.notify(`Could not switch model for role '${targetRole}'; keeping the current Pi model (${error.message}).`, "error");
      return false;
    }
  }

  function persistedRole(ctx) {
    const entries = ctx.sessionManager.getBranch();
    for (let i = entries.length - 1; i >= 0; i--) {
      const entry = entries[i];
      if (entry.type === "custom" && entry.customType === ENTRY_TYPE && typeof entry.data?.role === "string") {
        return entry.data.role;
      }
    }
    return DEFAULT_ROLE;
  }

  async function restoreRole(ctx) {
    const savedRole = persistedRole(ctx);
    try {
      const roles = await availableRoles();
      role = roles.includes(savedRole) ? savedRole : DEFAULT_ROLE;
      await rolePrompt(role);
    } catch {
      role = DEFAULT_ROLE;
    }
    await updateRoleStatus(ctx);
  }

  async function chooseRole(name, ctx) {
    const roles = await availableRoles();
    if (!name) {
      name = await ctx.ui.select("Switch primary role", roles);
      if (!name) return;
    }
    name = name.trim();
    if (!roles.includes(name)) {
      ctx.ui.notify(`Unknown role '${name}'. Use /role list.`, "error");
      return;
    }
    try {
      await rolePrompt(name);
    } catch {
      ctx.ui.notify(`Unknown role '${name}'. Use /role list.`, "error");
      return;
    }
    const previousRole = role;
    role = name;
    await applyRoleModel(name, ctx, { notifyUnmapped: true });
    pi.appendEntry(ENTRY_TYPE, { role: name });
    await updateRoleStatus(ctx);
    ctx.ui.notify(`Primary role: ${name}${previousRole === name ? " (unchanged)" : ""}`, "info");
  }

  function queueRoleCommand(args, ctx, cycle = false) {
    // Queue the whole transaction, including selection and persistence.
    const command = roleCommands.then(async () => {
      if (cycle) {
        const roles = await availableRoles();
        if (roles.length) await chooseRole(roles[(roles.indexOf(role) + 1) % roles.length], ctx);
        return;
      }
      const name = args.trim();
      if (name === "list") {
        const roles = await availableRoles();
        ctx.ui.notify(`Available roles: ${roles.join(", ")}\nCurrent role: ${role}`, "info");
        return;
      }
      await chooseRole(name, ctx);
    });
    // Keep failures visible to the caller without poisoning later commands.
    roleCommands = command.catch(() => {});
    return command;
  }

  pi.registerCommand("role", {
    description: "Show or switch the primary role (/role [name|list])",
    handler: queueRoleCommand,
  });

  pi.registerShortcut("ctrl+r", {
    description: "Cycle primary role",
    handler: (ctx) => queueRoleCommand("", ctx, true),
  });

  pi.registerShortcut("ctrl+alt+r", {
    description: "Select primary role",
    handler: (ctx) => queueRoleCommand("", ctx),
  });

  pi.on("session_start", async (_event, ctx) => await restoreRole(ctx));

  pi.on("session_tree", async (_event, ctx) => {
    await restoreRole(ctx);
  });

  pi.on("before_agent_start", async (event) => ({
    systemPrompt: `${event.systemPrompt}\n\n## Active primary role: ${role}\n\n${await rolePrompt(role)}\n\nRole prompts provide workflow guidance only and are not an authorization boundary.`,
  }));
}
