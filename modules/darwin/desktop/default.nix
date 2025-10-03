{
  pkgs,
  userConfig,
  ...
}: {
  # Additional desktop applications
  environment.systemPackages = with pkgs; [
    # Multimedia
    imagemagick

    # Development
    docker
    nodejs
    python3

    # Utilities
    mas # Mac App Store CLI
    rectangle # Window management
  ];

  # System preferences for desktop use
  system.defaults = {
    # Global preferences
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };

    # Activity Monitor
    ActivityMonitor = {
      OpenMainWindow = true;
      IconType = 2; # CPU Usage
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };

    # Login window
    loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = true;
    };
  };
}