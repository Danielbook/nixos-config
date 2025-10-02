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
    "${nhModules}/common"
    "${nhModules}/programs/git"
    "${nhModules}/programs/gpg"
    "${nhModules}/programs/ssh"
    "${nhModules}/programs/tmux"
    "${nhModules}/programs/zsh"
    "${nhModules}/programs/neovim"
    "${nhModules}/scripts"
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

  # macOS-specific programs
  programs = {
    # Terminal
    alacritty = {
      enable = true;
      settings = {
        window = {
          decorations = "buttonless";
          opacity = 0.95;
        };
        font = {
          normal.family = "JetBrains Mono Nerd Font";
          size = 14;
        };
      };
    };
  };

  # Enable Home Manager
  programs.home-manager.enable = true;
}