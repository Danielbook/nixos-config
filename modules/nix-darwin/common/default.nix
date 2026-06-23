{
  inputs,
  outputs,
  lib,
  userConfig,
  pkgs,
  ...
}:
{
  # Nixpkgs configuration
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config.allowUnfree = true;
  };

  # Register flake inputs for nix commands
  nix.registry = lib.mapAttrs (_: flake: { inherit flake; }) (
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
    feishin # Navidrome/Subsonic music client (matches the NixOS setup)
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
      "google-chrome"
      "zen"
      "ghostty"
      "claude"
      "discord"
      "docker-desktop"
      "home-assistant"
      "microsoft-excel"
      "microsoft-outlook"
      "microsoft-powerpoint"
      "microsoft-teams"
      "whatsapp"
    ];

    # Mac App Store apps (requires being signed into the App Store; `mas` is
    # pulled in automatically). WireGuard is MAS-only on macOS — no cask exists.
    # Import the home-vpn tunnel once from its .conf; see docs/WIREGUARD.md.
    masApps = {
      WireGuard = 1451685025;
      GarageBand = 682658836;
    };
  };

  # Touch ID for sudo. `reattach` pulls in pam_reattach so the prompt also
  # works inside tmux (Ghostty auto-attaches tmux); without it sudo silently
  # falls back to a password prompt in a tmux session.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  system.stateVersion = 6;
}
