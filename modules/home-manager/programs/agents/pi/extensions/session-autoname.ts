import { homedir } from "node:os";
import { join, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const repositories = join(homedir(), "Documents", "repositories");
const titleModels: [string, string, string][] = [
  [join(repositories, "personal") + sep, "claude-bridge", "claude-haiku-5-5"],
  [join(repositories, "work") + sep, "openai-codex", "gpt-6-luna"],
];

const textOf = (content: unknown): string =>
  typeof content === "string"
    ? content
    : Array.isArray(content)
      ? content.map((part) => (part?.type === "text" ? part.text : "")).join(" ")
      : "";

// Names an unnamed session after its first finished run, with a cheap model per repository root.
// ponytail: sessions outside the listed roots stay unnamed. Add a root to name them.
export default function (pi: ExtensionAPI) {
  let tried = false;
  let systemPrompt = "";
  pi.on("session_start", () => {
    tried = false;
  });
  // claude-bridge only accepts a system prompt it recorded from an agent turn.
  // After the run, getSystemPrompt() returns the base prompt without extension changes.
  pi.on("agent_start", (_event, ctx) => {
    systemPrompt = ctx.getSystemPrompt();
  });

  pi.on("agent_settled", async (event, ctx) => {
    if (tried || event.aborted || pi.getSessionName()) return;
    const root = titleModels.find(([prefix]) => (ctx.cwd + sep).startsWith(prefix));
    if (!root) return;
    const messages = ctx.sessionManager
      .getBranch()
      .flatMap((entry) => (entry.type === "message" ? [entry.message] : []));
    const prompt = textOf(messages.find((message) => message.role === "user")?.content).trim();
    if (!prompt) return;
    tried = true;

    const model = ctx.modelRegistry.find(root[1], root[2]);
    if (!model) return;
    const reply = textOf(messages.find((message) => message.role === "assistant")?.content);
    try {
      const response = await ctx.modelRegistry.complete(model, {
        systemPrompt,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Write a title for this coding-agent session. Do not use tools. Reply with only the title: at most 6 words, no quotes, no final punctuation.\n\nFirst prompt:\n${prompt.slice(0, 1000)}\n\nStart of first reply:\n${reply.slice(0, 800)}`,
              },
            ],
            timestamp: Date.now(),
          },
        ],
      });
      if (response.stopReason === "error" || response.stopReason === "aborted") return;
      const title = textOf(response.content)
        .trim()
        .split("\n")[0]
        .replace(/^["'`]+|["'`.!?]+$/g, "")
        .slice(0, 60);
      // A name set while the call ran wins.
      if (title && !pi.getSessionName()) pi.setSessionName(title);
    } catch {
      // The session stays unnamed. /name still works.
    }
  });
}
