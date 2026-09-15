import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const dangerousCommands: Array<[string, RegExp]> = [
  ["recursive delete", /\brm\s+(?:-[^\s]*r[^\s]*|--recursive)\b/i],
  ["sudo", /\bsudo\b/i],
  ["force push", /\bgit\s+push\b[^\n]*\s--force(?:-with-lease)?\b/i],
  ["git reset --hard", /\bgit\s+reset\s+--hard\b/i],
  ["git clean", /\bgit\s+clean\b/i],
  ["delete git branch", /\bgit\s+branch\s+-D\b/i],
  ["Kubernetes delete", /\bkubectl\s+delete\b/i],
  ["Terraform apply/destroy", /\bterraform\s+(?:apply|destroy)\b/i],
];

const secretPath = /(?:^|[\s"'=/])(?:~\/)?(?:\.env(?:\.[^/\s]+)?|\.ssh(?=\/|$)|[^/\s]+\.(?:pem|key|p12|pfx)|id_(?:rsa|ed25519)|credentials(?:\.[^/\s]+)?)(?=$|[\s"';&|/])/i;

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "bash") {
      const command = event.input.command as string;
      if (secretPath.test(command)) {
        return { block: true, reason: "Secret-path access is blocked" };
      }

      const dangerous = dangerousCommands.find(([, pattern]) => pattern.test(command));
      if (!dangerous) return;
      if (!ctx.hasUI) {
        return { block: true, reason: `${dangerous[0]} blocked: no confirmation UI` };
      }

      const allowed = await ctx.ui.confirm(
        "Dangerous command",
        `${dangerous[0]}:\n\n${command}\n\nAllow once?`,
      );
      if (!allowed) return { block: true, reason: `${dangerous[0]} blocked by user` };
      return;
    }

    if (!["read", "write", "edit"].includes(event.toolName)) return;
    const path = event.input.path as string;
    if (secretPath.test(path)) {
      return { block: true, reason: `Secret path is blocked: ${path}` };
    }
  });
}
