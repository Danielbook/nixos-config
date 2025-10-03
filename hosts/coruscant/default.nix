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

    brews = [
      "mas" # Mac App Store CLI
    ];

    # Only GUI applications that aren't available via Nix
    casks = [
      "ghostty"        # Modern terminal emulator
      "spotify"        # Music streaming
      "discord"        # Communication
      "obsidian"       # Note taking
      "visual-studio-code"  # Code editor
    ];
  };

}