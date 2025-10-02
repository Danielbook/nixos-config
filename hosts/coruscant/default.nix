{
  hostname,
  darwinModules,
  userConfig,
  ...
}: {
  imports = [
    "${darwinModules}/common"
    "${darwinModules}/desktop"
  ];

  # Set hostname
  networking.hostName = hostname;

  # System state version (keep in sync with latest nix-darwin)
  system.stateVersion = 6;

  # Homebrew integration
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    
    taps = [
      "homebrew/cask-fonts"
      "homebrew/services"
    ];
    
    brews = [
      "mas" # Mac App Store CLI
    ];
    
    # Only GUI applications that aren't available via Nix
    casks = [
      "spotify"        # Music streaming
      "discord"        # Communication
      "obsidian"       # Note taking
      "visual-studio-code"  # Code editor
    ];
    
    masApps = {
      "Xcode" = 497799835;
    };
  };

}