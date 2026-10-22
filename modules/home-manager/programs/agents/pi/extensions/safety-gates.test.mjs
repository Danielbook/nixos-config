import assert from "node:assert/strict";
import { homedir } from "node:os";
import { test } from "node:test";
import { check } from "./safety-gates.ts";

// A sample with the shape of policy.nix.
const policy = {
  secretNames: [".env", ".env.*", "*.pem", "id_ed25519*"],
  secretPaths: ["~/.ssh", "~/.kube/config"],
  protectedPaths: ["~/.zshrc"],
  deny: ["rm -rf /", "git init"],
  ask: ["sudo", "su", "rm -r", "rm -rf", "git push --force", "git push -f", "git branch -D"],
};
const bash = (command) => check(policy, "bash", { command })?.decision;
const file = (tool, path) => check(policy, tool, { path })?.decision;

test("deny tier blocks with no question", () => {
  assert.equal(bash("rm -rf /"), "block");
  assert.equal(bash("cd x && git init"), "block");
});

test("ask tier matches flags in any order and position", () => {
  assert.equal(bash("rm -fr build"), "ask");
  assert.equal(bash("rm -r -f build"), "ask");
  assert.equal(bash("git push origin main --force"), "ask");
  assert.equal(bash("git push -uf origin main"), "ask");
  assert.equal(bash("ls && sudo nixos-rebuild switch"), "ask");
  assert.equal(bash("git branch -D old"), "ask");
  assert.equal(bash("rm -rf /tmp/x"), "ask"); // "rm -rf /" denies only the root
});

test("ordinary commands pass", () => {
  assert.equal(bash("git push origin main"), undefined);
  assert.equal(bash("rm build/out.txt"), undefined);
  assert.equal(bash("sudoku --help"), undefined);
  assert.equal(bash("git branch -d merged"), undefined);
});

test("secret paths are blocked in bash text and file tools", () => {
  assert.equal(bash("cat .env"), "block");
  assert.equal(bash("source ./app/.env.local"), "block");
  assert.equal(bash("cat ~/.ssh/config"), "block");
  assert.equal(bash("kubectl --kubeconfig=$HOME/.kube/config get pods"), "block");
  assert.equal(bash("cat .envrc"), undefined);
  assert.equal(file("read", "certs/server.pem"), "block");
  assert.equal(file("read", `${homedir()}/.ssh/known_hosts`), "block");
  assert.equal(file("read", "src/env.ts"), undefined);
});

test("protected paths are read-only", () => {
  assert.equal(file("read", "~/.zshrc"), undefined);
  assert.equal(file("edit", "~/.zshrc"), "block");
  assert.equal(file("write", `${homedir()}/.zshrc`), "block");
});
