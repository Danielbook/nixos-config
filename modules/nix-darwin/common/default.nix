{
  inputs,
  outputs,
  lib,
  userConfig,
  pkgs,
  ...
}: {
  # Nixpkgs configuration
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config.allowUnfree = true;
  };

  # Register flake inputs for nix commands
  nix.registry = lib.mapAttrs (_: flake: {inherit flake;}) (
    lib.filterAttrs (_: lib.isType "flake") inputs
  );

  # Nix settings
  nix.settings = {
    experimental-features = "nix-command flakes";
  };

  # User definition
  users.users.${userConfig.name} = {
    home = "/Users/${userConfig.name}";
  };

  # Required by recent nix-darwin for homebrew and user-scoped system.defaults
  system.primaryUser = userConfig.name;

  # System packages
  environment.systemPackages = with pkgs; [
    sops
    just
  ];

  # Enable zsh at system level
  programs.zsh.enable = true;

  # macOS system defaults
  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      "com.apple.swipescrolldirection" = true;
    };
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };
  };

  # Homebrew for casks not in nixpkgs
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    casks = [
      "bitwarden"
      "brave-browser"
      "chatgpt"
      "firefox"
      "ghostty"
      "claude"
      "discord"
      "home-assistant"
      "messenger"
      "microsoft-excel"
      "microsoft-outlook"
      "microsoft-powerpoint"
      "microsoft-teams"
      "whatsapp"
    ];
  };

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 6;
}
