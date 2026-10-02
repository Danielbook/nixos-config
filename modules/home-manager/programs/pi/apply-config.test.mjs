import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

test("activation merges managed config, stays writable, preserves runtime state", () => {
  const dir = mkdtempSync(join(tmpdir(), "pi-config-"));
  const script = new URL("./apply-config.mjs", import.meta.url);
  const settings = join(dir, "settings.json");
  const mcp = join(dir, "mcp.json");
  const settingsDefaults = join(dir, "settings-defaults.json");
  const mcpDefaults = join(dir, "mcp-defaults.json");
  const apply = () => execFileSync(process.execPath, [script.pathname, dir, settingsDefaults, mcpDefaults], { stdio: "pipe" });
  const read = (path) => JSON.parse(readFileSync(path, "utf8"));
  try {
    writeFileSync(settingsDefaults, JSON.stringify({ packages: ["npm:example@1.0.0"], extensions: ["+builtin:mcp"] }));
    writeFileSync(mcpDefaults, JSON.stringify({ mcpServers: { playwright: { command: "managed" } } }));
    apply();
    assert.deepEqual(read(settings), read(settingsDefaults));
    assert.deepEqual(read(mcp), read(mcpDefaults));

    writeFileSync(settings, JSON.stringify({ packages: ["npm:pi-mcp-adapter"], extensions: ["-builtin:mcp"], quietStartup: true }));
    writeFileSync(mcp, JSON.stringify({ mcpServers: { playwright: { command: "old" }, personal: { command: "keep" } } }));
    writeFileSync(join(dir, "auth.json"), "runtime auth state");
    apply();
    assert.deepEqual(read(settings), { ...read(settingsDefaults), quietStartup: true });
    assert.deepEqual(read(mcp).mcpServers, { playwright: { command: "managed" }, personal: { command: "keep" } });
    assert.equal(readFileSync(join(dir, "auth.json"), "utf8"), "runtime auth state");
    const before = readFileSync(settings, "utf8");
    apply();
    assert.equal(readFileSync(settings, "utf8"), before);
    writeFileSync(settings, before);

    const original = join(dir, "original.json");
    writeFileSync(original, before);
    rmSync(settings);
    symlinkSync(original, settings);
    apply();
    writeFileSync(settings, "{}");
    assert.equal(readFileSync(original, "utf8"), before);

    for (const invalid of ["invalid JSON", "null", "[]", '{"mcpServers":null}', '{"mcpServers":[]}']) {
      writeFileSync(mcp, invalid);
      assert.throws(apply);
      assert.equal(readFileSync(settings, "utf8"), "{}");
      assert.equal(readFileSync(mcp, "utf8"), invalid);
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
