{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  userConfig,
  ...
}: {
  # Nixpkgs configuration
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      trusted-users = ["root" userConfig.name];
    };
    
    # Automatic garbage collection
    gc = {
      automatic = true;
      interval = {Weekday = 7;}; # Weekly on Sunday
      options = "--delete-older-than 30d";
    };

    # Register flake inputs for nix commands
    registry = lib.mapAttrs (_: flake: {inherit flake;}) (
      lib.filterAttrs (_: lib.isType "flake") inputs
    );
  };

  # User configuration
  users.users.${userConfig.name} = {
    name = userConfig.name;
    home = "/Users/${userConfig.name}";
  };

  # Security configuration
  security = {
    # Enable TouchID for sudo
    pam.services.sudo_local.touchIdAuth = true;
    
    # Passwordless sudo for user
    sudo.extraConfig = "${userConfig.name} ALL = (ALL) NOPASSWD: ALL";
  };

  # Comprehensive system defaults
  system = {
    defaults = {
      # Control Center settings
      controlcenter = {
        BatteryShowPercentage = true;
        NowPlaying = false;
      };

      # Global system preferences
      NSGlobalDomain = {
        # Sound and interface
        "com.apple.sound.beep.volume" = 0.0;
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        
        # Keyboard settings
        ApplePressAndHoldEnabled = false; # Disable press-and-hold for accent characters
        InitialKeyRepeat = 20; # Fast key repeat
        KeyRepeat = 2; # Very fast key repeat
        
        # Text and autocorrect
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        
        # Window and file behavior
        NSAutomaticWindowAnimationsEnabled = false; # Disable window animations
        NSDocumentSaveNewDocumentsToCloud = false; # Don't save to iCloud by default
        NSNavPanelExpandedStateForSaveMode = true; # Expand save panel
        PMPrintingExpandedStateForPrint = true; # Expand print panel
      };

      # Custom symbolic hotkeys and application preferences
      CustomUserPreferences = {
        # Symbolic hotkeys configuration
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Notification Center: Option + N
            "163" = {
              enabled = true;
              value = {
                parameters = [110 45 524288];
                type = "standard";
              };
            };
            # Screenshot options: Option + Shift + R
            "184" = {
              enabled = true;
              value = {
                parameters = [114 15 655360];
                type = "standard";
              };
            };
            # Disable Ctrl + Space for input source
            "60" = {
              enabled = false;
            };
            # Next input source: Option + Space
            "61" = {
              enabled = true;
              value = {
                parameters = [32 49 524288];
                type = "standard";
              };
            };
            # Disable Spotlight: Cmd + Space
            "64" = {
              enabled = false;
            };
            # Disable Finder search: Cmd + Option + Space
            "65" = {
              enabled = false;
            };
            # Center window: Ctrl + Cmd + C
            "238" = {
              enabled = true;
              value = {
                parameters = [99 8 1310720];
                type = "standard";
              };
            };
            # Disable Help menu
            "98" = {
              enabled = false;
            };
          };
        };

        # Global system preferences
        NSGlobalDomain = {
          "com.apple.mouse.linear" = true;
        };

        # Global keyboard shortcuts
        "-g" = {
          NSUserKeyEquivalents = {
            "Lock Screen" = "@^l";
            "Paste and Match Style" = "^$v";
          };
        };
      };

      # Disable app quarantine
      LaunchServices = {
        LSQuarantine = false;
      };

      # Trackpad configuration
      trackpad = {
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
        Clicking = true;
      };

      # Finder configuration
      finder = {
        AppleShowAllFiles = true; # Show hidden files
        CreateDesktop = false; # Don't show items on desktop
        FXDefaultSearchScope = "SCcf"; # Search current folder by default
        FXEnableExtensionChangeWarning = false; # Don't warn about extension changes
        FXPreferredViewStyle = "Nlsv"; # List view by default
        QuitMenuItem = true; # Allow quitting Finder
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true; # Show full path in title
        _FXSortFoldersFirst = true; # Sort folders first
      };

      # Dock configuration
      dock = {
        autohide = true;
        expose-animation-duration = 0.15; # Fast Mission Control animations
        show-recents = false;
        showhidden = true; # Show hidden applications
        persistent-apps = []; # Empty dock
        tilesize = 30; # Small dock size
        # Disable hot corners
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };

      # Screenshot configuration
      screencapture = {
        location = "/Users/${userConfig.name}/Downloads/temp";
        type = "png";
        disable-shadow = true;
      };
    };

    # Keyboard configuration
    keyboard = {
      enableKeyMapping = true;
      # Remap § key to ~ (useful for Nordic keyboards)
      userKeyMapping = [
        {
          HIDKeyboardModifierMappingDst = 30064771125; # ~
          HIDKeyboardModifierMappingSrc = 30064771172; # §
        }
      ];
    };

    # Set primary user
    primaryUser = userConfig.name;
  };

  # Essential system packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    curl
    wget
    git
    jq
    tree
    htop
    
    # Development tools
    vim
    neovim
    
    # Archive tools
    unzip
    p7zip
  ];

  # Shell configuration
  programs = {
    zsh.enable = true;
    bash.enable = true;
  };

  # Services
  services = {
    nix-daemon.enable = true;
  };

  # System fonts
  fonts = {
    packages = with pkgs; [
      # Programming fonts with Nerd Font variants
      (nerdfonts.override {fonts = ["FiraCode" "JetBrainsMono" "Meslo"];})
      fira-code
      jetbrains-mono
      
      # System fonts
      inter
      source-sans-pro
      source-serif-pro
    ];
  };

  # Time zone
  time.timeZone = "Europe/Stockholm";
}