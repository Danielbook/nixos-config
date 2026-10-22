import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// The agent policy, rendered by Nix from programs/agents/policy.nix.
export type Policy = {
  secretNames: string[];
  secretPaths: string[];
  protectedPaths: string[];
  deny: string[];
  ask: string[];
};

export type Verdict = { decision: "block" | "ask"; reason: string } | undefined;

const home = homedir();
const expandHome = (path: string) => path.replace(/^(?:~|\$HOME|\$\{HOME\})(?=\/|$)/, home);
const globToRegExp = (glob: string) =>
  new RegExp(`^${glob.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".")}$`);

function underAny(path: string, roots: string[]): boolean {
  const full = resolve(expandHome(path));
  return roots.some((root) => {
    const base = expandHome(root);
    return full === base || full.startsWith(`${base}/`);
  });
}

function isSecret(policy: Policy, path: string): boolean {
  const name = basename(path);
  return policy.secretNames.some((glob) => globToRegExp(glob).test(name)) || underAny(path, policy.secretPaths);
}

const words = (command: string) =>
  command
    .split(/\s+/)
    .filter(Boolean)
    .map((token) => token.replace(/^["']|["']$/g, ""));

// Command words must match from the start. Each flag of the prefix may sit
// anywhere after them, and short flags may combine: "rm -rf" matches "rm -fr x".
export function matchesPrefix(command: string[], prefix: string[]): boolean {
  const firstFlag = prefix.findIndex((token) => token.startsWith("-"));
  const head = firstFlag === -1 ? prefix : prefix.slice(0, firstFlag);
  const rest = firstFlag === -1 ? [] : prefix.slice(firstFlag);
  if (!head.every((token, i) => command[i] === token)) return false;
  const tail = command.slice(head.length);
  const shortFlags = new Set(tail.filter((token) => /^-[^-]/.test(token)).flatMap((token) => [...token.slice(1)]));
  return rest.every((token) =>
    !token.startsWith("-") || token.startsWith("--")
      ? tail.includes(token)
      : [...token.slice(1)].every((letter) => shortFlags.has(letter)),
  );
}

export function check(policy: Policy, toolName: string, input: Record<string, unknown>): Verdict {
  if (toolName === "bash") {
    const text = String(input.command ?? "");
    if (text.split(/[\s"'=;&|<>()`]+/).some((token) => token && isSecret(policy, token))) {
      return { decision: "block", reason: "Secret-path access is blocked" };
    }
    const commands = text.split(/&&|\|\||[;|&\n]/).map(words);
    const hit = (prefixes: string[]) =>
      prefixes.find((prefix) => commands.some((command) => matchesPrefix(command, prefix.split(" "))));
    const denied = hit(policy.deny);
    if (denied) return { decision: "block", reason: `"${denied}" is blocked by the agent policy` };
    const asked = hit(policy.ask);
    if (asked) return { decision: "ask", reason: asked };
    return;
  }

  if (!["read", "write", "edit"].includes(toolName)) return;
  const path = String(input.path ?? "");
  if (isSecret(policy, path)) return { decision: "block", reason: `Secret path is blocked: ${path}` };
  if (toolName !== "read" && underAny(path, policy.protectedPaths)) {
    return { decision: "block", reason: `Protected path is read-only: ${path}` };
  }
}

export default function (pi: ExtensionAPI) {
  let policy: Policy | undefined;
  try {
    policy = JSON.parse(readFileSync(`${home}/.pi/agent/safety-policy.json`, "utf8"));
  } catch {
    // Fail closed: without the policy, block every tool call.
  }

  pi.on("tool_call", async (event, ctx) => {
    if (!policy) return { block: true, reason: "Agent policy is missing: ~/.pi/agent/safety-policy.json" };
    const verdict = check(policy, event.toolName, event.input);
    if (!verdict) return;
    if (verdict.decision === "block") return { block: true, reason: verdict.reason };
    if (!ctx.hasUI) return { block: true, reason: `${verdict.reason} blocked: no confirmation UI` };

    const allowed = await ctx.ui.confirm(
      "Dangerous command",
      `${verdict.reason}:\n\n${event.input.command}\n\nAllow once?`,
    );
    if (!allowed) return { block: true, reason: `${verdict.reason} blocked by user` };
  });
}
