import { homedir } from "node:os";
import { join, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const personal = join(homedir(), "Documents", "repositories", "personal") + sep;

// New sessions under the personal repositories use Claude Opus 5.5.
// Resumed sessions keep their model. A --model flag takes precedence.
export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (event, ctx) => {
    if (event.reason !== "startup" && event.reason !== "new") return;
    if (!(ctx.cwd + sep).startsWith(personal)) return;
    if (process.argv.some((arg) => arg.startsWith("--model"))) return;
    if (ctx.sessionManager.getEntries().some((entry) => entry.type === "message")) return;
    const model = ctx.modelRegistry.find("claude-bridge", "claude-opus-5-5");
    if (model) await pi.setModel(model);
  });
}
