{ pkgs, ... }:
{
  # Noctalia desktop shell - bar, notifications, lock screen, control center
  # Settings are managed by Noctalia UI (not declarative) to allow easy tweaking
  programs.noctalia-shell.enable = true;

  # Noctalia runtime dependencies
  home.packages = with pkgs; [
    imagemagick
  ];
}
