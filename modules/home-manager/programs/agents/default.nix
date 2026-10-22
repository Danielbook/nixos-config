# Coding agents: Claude Code, Codex and Pi. Shared data: mcp-servers.nix (the
# MCP registry), policy.nix (the agent policy) and agent-instructions.md. Each
# adapter renders them in the format of its agent.
{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./claude.nix
    ./codex.nix
    ./pi
  ];

  # On PATH for its CLI and for the worktrunk hooks below.
  home.packages = [ pkgs.codebase-memory-mcp ];

  # npm installs the latest agent CLIs (nixpkgs lags behind). claude-code is
  # npm-installed on Linux only. On darwin it uses the native installer
  # (`claude install` → ~/.local/bin).
  home.activation.installAgents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export npm_config_prefix="$HOME/.npm-global"
    PATH="${pkgs.nodejs_24}/bin:$PATH"
    $DRY_RUN_CMD ${pkgs.nodejs_24}/bin/npm install -g \
      ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux "@anthropic-ai/claude-code@latest"} \
      @openai/codex@latest \
      2>&1 | tail -5
    $DRY_RUN_CMD ${pkgs.nodejs_24}/bin/npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest
  '';

  # Each wt worktree is a separate path, so index it on create and drop its
  # graph on remove. Project names are the path with `/` mapped to `-`.
  xdg.configFile."worktrunk/config.toml".text =
    let
      cbm = pkgs.writeShellScript "cbm-worktree" ''
        jq=${lib.getExe pkgs.jq}
        case "$1" in
          index) tool=index_repository arg=$($jq -nc --arg p "$2" '{repo_path: $p}') ;;
          delete) tool=delete_project arg=$($jq -nc --arg p "$2" '{project: ($p | ltrimstr("/") | gsub("/"; "-"))}') ;;
          *) exit 2 ;;
        esac
        exec ${lib.getExe pkgs.codebase-memory-mcp} cli "$tool" "$arg"
      '';
    in
    ''
      post-start = "${cbm} index {{ worktree_path }}"
      post-remove = "${cbm} delete {{ worktree_path }}"
    '';

  # Codex, Pi and the other agents read ~/.agents/skills. Claude Code reads
  # ~/.claude/skills. The other skills there are installed with `npx skills`.
  home.file.".agents/skills/security-audit".source =
    "${inputs.security-audit-skill}/skills/security-audit";
  home.file.".claude/skills/security-audit".source =
    "${inputs.security-audit-skill}/skills/security-audit";

  # Caveman plugin default intensity (plugin itself installed imperatively)
  xdg.configFile."caveman/config.json".text = builtins.toJSON {
    defaultMode = "ultra";
  };
}
