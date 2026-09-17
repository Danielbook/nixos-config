import { basename } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

type Usage = {
  input?: number;
  output?: number;
  cacheRead?: number;
  cacheWrite?: number;
  cost?: { total?: number };
};

const formatTokens = (count: number) =>
  count < 1000 ? `${count}` : count < 10000 ? `${(count / 1000).toFixed(1)}k` : `${Math.round(count / 1000)}k`;

const openAIContextPolicy: Record<string, { longContextAt: number }> = {
  "gpt-5.6-terra": { longContextAt: 272_000 },
  "gpt-5.6-sol": { longContextAt: 272_000 },
  "gpt-6-astra": { longContextAt: 272_000 },
};

const catppuccin = {
  blue: "8aadf4",
  peach: "f5a97f",
  green: "a6da95",
  yellow: "eed49f",
  red: "ed8796",
};

const color = (hex: string, text: string) => `\x1b[38;2;${parseInt(hex.slice(0, 2), 16)};${parseInt(hex.slice(2, 4), 16)};${parseInt(hex.slice(4, 6), 16)}m${text}\x1b[0m`;

export default function (pi: ExtensionAPI) {
  async function refresh(ctx: ExtensionContext) {
    const result = await pi.exec("git", ["status", "--porcelain=v1", "-b"], {
      timeout: 2000,
      signal: ctx.signal,
    });
    if (result.code !== 0) {
      ctx.ui.setStatus("git-diff", undefined);
      return;
    }

    const [head, ...changes] = result.stdout.trimEnd().split("\n");
    const branch = head?.startsWith("## ") ? head.slice(3).split("...")[0] : "detached";
    const count = changes.filter(Boolean).length;
    ctx.ui.setStatus(
      "git-diff",
      ctx.ui.theme.fg(count ? "warning" : "dim", `git:${branch} ${count ? `${count} changed` : "clean"}`),
    );
  }

  function installFooter(ctx: ExtensionContext) {
    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
      return {
        dispose: unsubscribe,
        invalidate() {},
        render(width: number) {
          const totals = { input: 0, output: 0, cost: 0 };
          for (const entry of ctx.sessionManager.getEntries()) {
            const usage = (entry.type === "message" ? entry.message.usage : entry.usage) as Usage | undefined;
            if (!usage) continue;
            totals.input += usage.input ?? 0;
            totals.output += usage.output ?? 0;
            totals.cost += usage.cost?.total ?? 0;
          }

          const home = process.env.HOME;
          const cwd = home && ctx.cwd.startsWith(`${home}/`) ? `~${ctx.cwd.slice(home.length)}` : ctx.cwd;
          const branch = footerData.getGitBranch();
          const context = ctx.getContextUsage();
          const window = formatTokens(context?.contextWindow ?? ctx.model?.contextWindow ?? 0);
          const usedTokens = context?.tokens == null ? "?" : formatTokens(context.tokens);
          const contextText = context?.percent == null
            ? `${usedTokens}/${window} (auto)`
            : `${context.percent.toFixed(1)}% ${usedTokens}/${window} (auto)`;
          const policy = ctx.model ? openAIContextPolicy[ctx.model.id] : undefined;
          const policyLimit = policy
            ? Math.min(context?.contextWindow ?? ctx.model?.contextWindow ?? policy.longContextAt, policy.longContextAt)
            : undefined;
          const yellowAt = policyLimit ? policyLimit * 0.7 : undefined;
          const redAt = policyLimit ? policyLimit * 0.9 : undefined;
          const contextColor = context?.percent == null
            ? "dim"
            : redAt !== undefined && context.tokens >= redAt
              ? "error"
              : yellowAt !== undefined && context.tokens >= yellowAt
                ? "warning"
                : "success";
          const contextStyle = contextColor === "success"
            ? (text: string) => color(catppuccin.green, text)
            : contextColor === "warning"
              ? (text: string) => color(catppuccin.yellow, text)
              : contextColor === "error"
                ? (text: string) => color(catppuccin.red, text)
                : (text: string) => theme.fg("dim", text);
          const stats = [
            totals.input && color(catppuccin.blue, `↑${formatTokens(totals.input)}`),
            totals.output && color(catppuccin.peach, `↓${formatTokens(totals.output)}`),
            totals.cost && color(catppuccin.green, `$${totals.cost.toFixed(3)}${ctx.model?.provider === "openai-codex" ? " (sub)" : ""}`),
          ].filter(Boolean).join(" ");
          const model = `${ctx.model?.id ?? "no-model"}${ctx.model?.reasoning ? ` • ${ctx.thinkingLevel}` : ""}`;
          const pad = " ".repeat(Math.max(2, width - visibleWidth(`${stats} ${contextText}`) - visibleWidth(model)));
          const statuses = [...footerData.getExtensionStatuses().entries()]
            .sort(([a], [b]) => a.localeCompare(b))
            .map(([, text]) => text.replace(/[\r\n\t]+/g, " ").trim())
            .join(" ");

          return [
            truncateToWidth(theme.fg("dim", `${cwd}${branch ? ` (${branch})` : ""}`), width),
            truncateToWidth(
              `${stats} ${contextStyle(contextText)}${pad}${theme.fg("dim", model)}`,
              width,
            ),
            ...(statuses ? [truncateToWidth(statuses, width)] : []),
          ];
        },
      };
    });
  }

  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setTitle(`pi · ${basename(ctx.cwd)} · ready`);
    installFooter(ctx);
    await refresh(ctx);
  });

  pi.on("agent_start", async (_event, ctx) => {
    ctx.ui.setTitle(`pi · ${basename(ctx.cwd)} · working`);
  });

  pi.on("agent_settled", async (_event, ctx) => {
    ctx.ui.setTitle(`pi · ${basename(ctx.cwd)} · ready`);
    await refresh(ctx);
  });
}
