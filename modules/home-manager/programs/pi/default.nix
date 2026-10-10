{
  lib,
  pkgs,
  ...
}:
let
  settings = pkgs.writeText "pi-settings.json" (
    builtins.toJSON {
      defaultProvider = "openai-codex";
      defaultModel = "gpt-6.1-sol";
      defaultThinkingLevel = "medium";
      theme = "dark";
      extensions = [ "+builtin:mcp" ];
      packages = [
        "git:github.com/DietrichGebert/ponytail@e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156"
        "npm:pi-web-search"
        "npm:pi-subagents"
        "npm:@juicesharp/rpiv-ask-user-question"
      ];
    }
  );
  playwrightCommand =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.writeShellScript "playwright-mcp-writable" ''
        export PLAYWRIGHT_BROWSERS_PATH="$HOME/.cache/playwright-mcp"
        # Bypass the outer Nix wrapper, which forces a read-only browser cache.
        exec ${pkgs.playwright-mcp}/bin/.playwright-mcp-wrapped "$@"
      ''
    else
      lib.getExe pkgs.playwright-mcp;
  mcp = pkgs.writeText "pi-mcp.json" (
    builtins.toJSON {
      mcpServers.playwright = {
        command = "${playwrightCommand}";
        args = [
          "--headless"
          "--browser"
          (if pkgs.stdenv.hostPlatform.isDarwin then "chrome" else "chromium")
        ];
      };
      # Default codemode exposure hides the tools, so Pi never reached for them.
      mcpServers.codebase-memory-mcp = {
        command = lib.getExe pkgs.codebase-memory-mcp;
        toolExposure = {
          search_graph = "direct";
          trace_path = "direct";
          get_code_snippet = "direct";
          query_graph = "direct";
          search_code = "direct";
          get_architecture = "direct";
          index_status = "direct";
        };
      };
      # Figma allowlists OAuth clients by name; Pi's own name is rejected.
      mcpServers.figma = {
        url = "https://mcp.figma.com/mcp";
        oauth.clientName = "Claude Code";
      };
    }
  );
in
{
  home.file = {
    ".pi/agent/extensions/caveman-default.ts" = {
      source = ./extensions/caveman-default.ts;
      force = true;
    };
    ".pi/agent/extensions/safety-gates.ts" = {
      source = ./extensions/safety-gates.ts;
      force = true;
    };
    ".pi/agent/extensions/status-and-git.ts" = {
      source = ./extensions/status-and-git.ts;
      force = true;
    };
  };

  home.activation.configurePi =
    lib.hm.dag.entryAfter
      [
        "installNpmCLITools"
        "linkGeneration"
      ]
      ''
        export npm_config_prefix="$HOME/.npm-global"
        export PATH="${
          lib.makeBinPath [
            pkgs.nodejs_24
            pkgs.git
          ]
        }:$PATH"
        $DRY_RUN_CMD ${pkgs.nodejs_24}/bin/npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest
        $DRY_RUN_CMD ${pkgs.nodejs_24}/bin/node ${./apply-config.mjs} "$HOME/.pi/agent" ${settings} ${mcp}
        # Skip the user's https->ssh insteadOf rewrite; activation has no ssh/agent.
        GIT_CONFIG_GLOBAL=/dev/null $DRY_RUN_CMD "$HOME/.npm-global/bin/pi" update --extensions --no-approve
      '';
}
