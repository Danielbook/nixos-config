{ ... }:
{
  home.file = {
    ".pi/agent/extensions/safety-gates.ts" = {
      source = ./extensions/safety-gates.ts;
      force = true;
    };
    ".pi/agent/extensions/status-and-git.ts" = {
      source = ./extensions/status-and-git.ts;
      force = true;
    };
  };
}
