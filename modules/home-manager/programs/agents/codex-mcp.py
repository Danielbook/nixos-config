"""Merge the Nix MCP servers into the Codex config.toml.

Codex writes other keys at runtime (trust levels, plugins, app servers). This
script replaces only the [mcp_servers.<name>] tables that Nix owns and keeps
all other text, comments and key order.

Usage: codex-mcp.py CONFIG_TOML SERVERS_JSON
"""

import json
import os
import sys

import tomlkit

config_path, servers_path = sys.argv[1], sys.argv[2]
with open(servers_path) as f:
    servers = json.load(f)

try:
    with open(config_path) as f:
        before = f.read()
    mode = os.stat(config_path).st_mode & 0o777
except FileNotFoundError:
    before = ""
    mode = 0o600  # Codex can store OAuth client secrets here.

doc = tomlkit.parse(before)
if "mcp_servers" not in doc:
    doc["mcp_servers"] = tomlkit.table(is_super_table=True)
for name, server in servers.items():
    table = tomlkit.table()
    table.update(server)
    doc["mcp_servers"][name] = table

after = tomlkit.dumps(doc)
if after != before:
    os.makedirs(os.path.dirname(config_path), exist_ok=True)
    temporary = f"{config_path}.nix-{os.getpid()}"
    with open(os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, mode), "w") as f:
        f.write(after)
    os.replace(temporary, config_path)
