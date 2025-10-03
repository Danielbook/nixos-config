{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  userConfig,
  nhModules,
  ...
}: {
  imports = [
    "${nhModules}/common-darwin"
  ];

  # User information
  home = {
    username = userConfig.name;
    homeDirectory = "/Users/${userConfig.name}";
    stateVersion = "25.05";
  };

  # macOS-specific packages
  home.packages = with pkgs; [
    # Development tools
    gh
    jq

    # Utilities
    rectangle # Window management
    raycast    # Spotlight replacement
  ];

  # macOS-specific overrides for Alacritty
  programs.alacritty.settings = {
    window.decorations = lib.mkForce "buttonless";
    font.size = lib.mkForce 14;
  };

  # Enable Home Manager
  programs.home-manager.enable = true;
}