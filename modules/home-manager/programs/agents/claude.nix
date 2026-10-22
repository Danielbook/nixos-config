# Claude Code adapter for the MCP registry, the agent policy and the
# instructions file.
{ lib, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  policy = import ./policy.nix;
  servers = lib.filterAttrs (_: s: lib.elem "claude" s.agents) (
    import ./mcp-servers.nix { inherit lib pkgs; }
  );

  # `//**/` matches in any directory. `/**` covers all files below a path.
  nameRules = tool: name: [ "${tool}(//**/${name})" ];
  pathRules = tool: path: [
    "${tool}(${path})"
    "${tool}(${path}/**)"
  ];
  # A prefix matches the bare command and the command with more arguments.
  bashRules = prefix: [
    "Bash(${prefix})"
    "Bash(${prefix} *)"
  ];

  # Nix owns the whole `permissions` key. Edit rules also cover Write.
  permissions = {
    defaultMode = "auto";
    allowedTools = [
      "Read"
      "Write"
      "Edit"
      "Glob"
      "Grep"
      "Bash"
      "Task"
    ];
    allow = [
      "Bash(*)"
      "Read(*)"
      "WebSearch"
      "WebFetch"
    ]
    ++ map (name: "mcp__${name}__*") (lib.attrNames servers);
    deny =
      lib.concatMap (name: nameRules "Read" name ++ nameRules "Edit" name) policy.secretNames
      ++ lib.concatMap (path: pathRules "Read" path ++ pathRules "Edit" path) policy.secretPaths
      ++ map (path: "Edit(${path})") policy.protectedPaths
      ++ lib.concatMap bashRules policy.deny;
    ask = lib.concatMap bashRules policy.ask;
  };

  # Seeded once, then owned by Claude Code at runtime, so that `claude plugin
  # install/uninstall` can change it. To seed again, delete
  # ~/.claude/settings.json and rebuild.
  seed = pkgs.writeText "claude-settings-seed.json" (
    builtins.toJSON {
      enabledPlugins = {
        "frontend-design@claude-code-plugins" = true;
      };
      alwaysThinkingEnabled = true;
      hooks = {
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = ''SA_BASE="''${CLAUDE_PROJECT_DIR:-.}/.claude/sa/.sessions/.id-gen"; [ -d "$SA_BASE" ] && find "$SA_BASE" -maxdepth 1 -mindepth 1 -type d -empty -delete 2>/dev/null || true'';
                timeout = 5;
              }
            ];
          }
        ];
      };
    }
  );

  servers' = lib.mapAttrs (
    _: s:
    if s ? url then
      {
        type = "http";
        inherit (s) url;
      }
    else
      {
        type = "stdio";
        inherit (s) command;
        args = s.args or [ ];
      }
  ) servers;

  # Merge only our keys into a file that Claude Code rewrites at runtime.
  jqMerge = file: filter: arg: ''
    tmp=$(mktemp "${file}.XXXXXX")
    { cat "${file}" 2>/dev/null || echo '{}'; } \
      | ${lib.getExe pkgs.jq} --argjson v ${lib.escapeShellArg (builtins.toJSON arg)} '${filter}' > "$tmp"
    $DRY_RUN_CMD mv "$tmp" "${file}"
    rm -f "$tmp"
  '';
in
{
  home.file.".claude/CLAUDE.md".source = ./agent-instructions.md;

  # The npm install has no auto-update. Nix handles upgrades.
  home.sessionVariables.DISABLE_AUTOUPDATER = lib.mkIf isLinux "1";

  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    if [ ! -e "$settings" ] || [ -L "$settings" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.claude"
      $DRY_RUN_CMD rm -f "$settings"
      $DRY_RUN_CMD install -m 0644 ${seed} "$settings"
    fi
    ${jqMerge "$settings" ".permissions = $v" permissions}
  '';

  # User-scope MCP servers live in ~/.claude.json. Servers added by hand stay.
  home.activation.registerClaudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="$HOME/.claude.json"
    ${jqMerge "$cfg" ".mcpServers += $v" servers'}
  '';
}
