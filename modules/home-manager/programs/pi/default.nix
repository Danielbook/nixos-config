{
  lib,
  pkgs,
  nhModules,
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
        "npm:agent-simple-english"
      ];
    }
  );
  # Pi adapter for the shared registry. Extras under `pi` merge into the server.
  piServers = lib.filterAttrs (_: s: lib.elem "pi" s.agents) (
    import "${nhModules}/common/mcp-servers.nix" { inherit lib pkgs; }
  );
  mcp = pkgs.writeText "pi-mcp.json" (
    builtins.toJSON {
      mcpServers = lib.mapAttrs (
        _: s:
        removeAttrs s [
          "agents"
          "pi"
        ]
        // s.pi or { }
      ) piServers;
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
