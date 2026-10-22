# Codex adapter for the MCP registry, the agent policy and the instructions
# file. The secret paths of the policy do not reach Codex: its per-path deny
# (permission profiles) is beta and covers only the sandboxed shell.
{ lib, pkgs, ... }:
let
  policy = import ./policy.nix;
  servers =
    lib.mapAttrs
      (
        _: s:
        if s ? url then
          { inherit (s) url; }
        else
          {
            inherit (s) command;
            args = s.args or [ ];
          }
      )
      (
        lib.filterAttrs (_: s: lib.elem "codex" s.agents) (import ./mcp-servers.nix { inherit lib pkgs; })
      );

  # JSON lists and strings are valid Starlark.
  rule = decision: prefix: ''
    prefix_rule(pattern = ${builtins.toJSON (lib.splitString " " prefix)}, decision = "${decision}", justification = "agent policy (nixos-config)")
  '';
  python = pkgs.python3.withPackages (p: [ p.tomlkit ]);
in
{
  home.file.".codex/AGENTS.md".source = ./agent-instructions.md;

  # Codex appends "always allow" answers to rules/default.rules. Nix owns only
  # this file. The most restrictive matching rule wins.
  home.file.".codex/rules/nix.rules".text =
    lib.concatMapStrings (rule "forbidden") policy.deny
    + lib.concatMapStrings (rule "prompt") policy.ask;

  # Codex rewrites config.toml at runtime. Merge only our MCP servers.
  home.activation.registerCodexMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${python}/bin/python3 -I ${./codex-mcp.py} "$HOME/.codex/config.toml" ${pkgs.writeText "codex-mcp.json" (builtins.toJSON servers)}
  '';
}
