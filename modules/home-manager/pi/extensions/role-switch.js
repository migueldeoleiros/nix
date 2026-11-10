import { readFile } from "node:fs/promises";
import { join } from "node:path";

const ENTRY_TYPE = "nix-primary-role";
const DEFAULT_ROLE = "assistant";

export default function (pi) {
  // Child agents inherit this extension but must retain their own prompt/model.
  // Return before registering hooks; do not alter any other extensions' state.
  if (
    process.env.PI_SUBAGENT_CHILD === "1" ||
    Boolean(process.env.PI_SUBAGENT_AGENT || process.env.PI_SUBAGENT_SESSION || process.env.PI_SUBAGENT_ID)
  ) return;

  const agentDir = process.env.PI_CODING_AGENT_DIR;
  let role = DEFAULT_ROLE;
  let roleCommands = Promise.resolve();

  async function availableRoles() {
    return JSON.parse(await readFile(join(agentDir, "roles.json"), "utf8"));
  }

  async function rolePrompt(name) {
    return readFile(join(agentDir, "prompts", `${name}.md`), "utf8");
  }

  async function roleModels() {
    try {
      return JSON.parse(await readFile(join(agentDir, "role-models.json"), "utf8"));
    } catch (error) {
      if (error.code === "ENOENT") return {};
      throw error;
    }
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
    ctx.ui.setStatus("primary-role", `role: ${role}`);
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
    ctx.ui.setStatus("primary-role", `role: ${name}`);
    ctx.ui.notify(`Primary role: ${name}${previousRole === name ? " (unchanged)" : ""}`, "info");
  }

  pi.registerCommand("role", {
    description: "Show or switch the primary role (/role [name|list])",
    handler: (args, ctx) => {
      // Queue the whole transaction, including selection and persistence.
      const command = roleCommands.then(async () => {
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
    },
  });

  pi.on("session_start", async (_event, ctx) => await restoreRole(ctx));

  pi.on("session_tree", async (_event, ctx) => {
    await restoreRole(ctx);
  });

  pi.on("before_agent_start", async (event) => ({
    systemPrompt: `${event.systemPrompt}\n\n## Active primary role: ${role}\n\n${await rolePrompt(role)}\n\nRole prompts provide workflow guidance only and are not an authorization boundary.`,
  }));
}
