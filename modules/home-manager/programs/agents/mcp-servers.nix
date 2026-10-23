# MCP servers for every agent. A server sets `command` and `args` (stdio) or
# `url` (remote HTTP). `agents` lists the agents that get it. Keys under `pi`
# go only into the Pi config. Adapters: claude.nix, codex.nix and pi/.
{ lib, pkgs }:
let
  playwrightCommand =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.writeShellScript "playwright-mcp-writable" ''
        export PLAYWRIGHT_BROWSERS_PATH="$HOME/.cache/playwright-mcp"
        # Bypass the outer Nix wrapper, which forces a read-only browser cache.
        exec ${pkgs.playwright-mcp}/bin/.playwright-mcp-wrapped "$@"
      ''
    else
      lib.getExe pkgs.playwright-mcp;
in
{
  playwright = {
    agents = [
      "pi"
      "claude"
      "codex"
    ];
    command = "${playwrightCommand}";
    args = [
      "--headless"
      "--browser"
      (if pkgs.stdenv.hostPlatform.isDarwin then "chrome" else "chromium")
    ];
  };
  codebase-memory-mcp = {
    agents = [
      "pi"
      "claude"
      "codex"
    ];
    command = lib.getExe pkgs.codebase-memory-mcp;
    # Default codemode exposure hides the tools, so Pi never reached for them.
    pi.toolExposure = {
      search_graph = "direct";
      trace_path = "direct";
      get_code_snippet = "direct";
      query_graph = "direct";
      search_code = "direct";
      get_architecture = "direct";
      index_status = "direct";
    };
  };
  testiny = {
    agents = [ "pi" ];
    url = "https://app.testiny.io/api/v1/mcp-server";
    headers.Authorization = "Bearer \${TESTINY_API_KEY}";
  };
  # Needs the MCP Server integration enabled in Home Assistant.
  homeassistant = {
    agents = [ "pi" ];
    url = "https://homeassistant.local.bookorjeman.com/api/mcp";
    headers.Authorization = "Bearer \${HOMEASSISTANT_TOKEN}";
  };
  # Figma allowlists OAuth clients by name. It rejects the name of Pi.
  figma = {
    agents = [ "pi" ];
    url = "https://mcp.figma.com/mcp";
    pi.oauth.clientName = "Claude Code";
  };
  miro = {
    agents = [
      "pi"
      "claude"
    ];
    url = "https://mcp.miro.com/";
  };
}
