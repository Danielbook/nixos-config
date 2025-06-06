{ config, pkgs, ... }: {
  # Enable Ghostty via Home Manager
  programs.ghostty = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";

      font-family = "JetBrains Mono";
      font-size = 13;

      background-opacity = 0.93;
    };
  };

  # Install Ghostty in your environment (just in case)
  home.packages = with pkgs; [
    ghostty
  ];
}
