import { mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const [agentDir, settingsDefaults, mcpDefaults] = process.argv.slice(2);

function readConfig(path) {
  let text;
  try {
    text = readFileSync(path, "utf8");
  } catch (error) {
    if (error.code === "ENOENT") return {};
    throw error;
  }
  const config = JSON.parse(text);
  if (!config || typeof config !== "object" || Array.isArray(config)) {
    throw new Error(`Expected JSON object: ${path}`);
  }
  return config;
}

// Validate both files before changing either.
const configs = [
  ["settings.json", settingsDefaults],
  ["mcp.json", mcpDefaults],
].map(([name, defaultsPath]) => {
  const path = join(agentDir, name);
  const current = readConfig(path);
  const defaults = readConfig(defaultsPath);
  const merged = { ...current, ...defaults };
  if (name === "mcp.json") {
    for (const config of [current, defaults]) {
      const servers = config.mcpServers;
      if (servers !== undefined && (!servers || typeof servers !== "object" || Array.isArray(servers))) {
        throw new Error(`Expected mcpServers object: ${path}`);
      }
    }
    merged.mcpServers = { ...current.mcpServers, ...defaults.mcpServers };
  }
  return [path, JSON.stringify(merged, null, 2) + "\n"];
});

mkdirSync(agentDir, { recursive: true });
for (const [path, text] of configs) {
  const temporary = `${path}.nix-${process.pid}`;
  writeFileSync(temporary, text, { mode: 0o600, flag: "wx" });
  renameSync(temporary, path);
}
