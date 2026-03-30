{
  inputs,
  outputs,
  lib,
  config,
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

  # Add inputs to legacy channels
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  # Nix settings
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };

  # Boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages; # Use latest stable kernel
    consoleLogLevel = 0; # Minimal boot messages
    initrd.verbose = false; # Quiet initramfs
    kernelParams = [
      "quiet" # Reduce kernel messages
      "splash" # Show boot splash
      "rd.udev.log_level=3" # Minimal udev logging
      # Essential suspend configuration
      "mem_sleep_default=deep" # Prefer S3 suspend-to-RAM over S0ix
      
      # Network driver stability parameters
      "r8152.enable_aldps=0"    # Disable Advanced Link Down Power Save for RTL8152/8153
      "pci=pcie_bus_perf"       # PCIe performance mode
      "iwlwifi.power_save=0"    # Disable WiFi power saving
      "iwlwifi.uapsd_disable=1" # Disable U-APSD power saving
    ];
    loader.efi.canTouchEfiVariables = true; # Allow EFI variable modification
    loader.systemd-boot = {
      enable = true; # Use systemd-boot bootloader
      configurationLimit = 10; # Keep last 10 generations
    };
    loader.timeout = 10; # Boot menu timeout (seconds)
    plymouth.enable = true; # Graphical boot splash

    # v4l (virtual camera) module settings
    #kernelModules = ["v4l2loopback"];
    #extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
    #extraModprobeConfig = ''
    #  options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    #'';
  };

  # Networking
  networking.networkmanager = {
    enable = true;
    
    # Automatically prefer ethernet over WiFi
    dispatcherScripts = [
      {
        source = pkgs.writeText "prefer-ethernet" ''
          #!/bin/sh
          # Automatically disable WiFi when ethernet is connected
          # and re-enable when ethernet is disconnected
          
          interface="$1"
          action="$2"
          
          case "$action" in
            "up")
              if [[ "$interface" =~ ^(eth|en) ]]; then
                # Ethernet came up, disable WiFi
                nmcli radio wifi off
                logger "NetworkManager: Disabled WiFi because ethernet ($interface) is connected"
              fi
              ;;
            "down")
              if [[ "$interface" =~ ^(eth|en) ]]; then
                # Ethernet went down, check if any other ethernet is up
                if ! nmcli device status | grep -E '^(eth|en).*connected'; then
                  # No ethernet connected, enable WiFi
                  nmcli radio wifi on
                  logger "NetworkManager: Enabled WiFi because no ethernet is connected"
                fi
              fi
              ;;
          esac
        '';
        type = "basic";
      }
    ];

    # Network stability settings
    settings = {
      main = {
        # Don't randomize MAC addresses (can cause connection issues)
        "wifi.scan-rand-mac-address" = "no";

        # Use internal DHCP client for better stability
        "dhcp" = "internal";

        # DNS settings for better connectivity
        "dns" = "default";
      };

      # Connection stability settings
      connection = {
        # Autoconnect settings for better reliability
        "connection.autoconnect-retries" = "0"; # Retry indefinitely
        "connection.auth-retries" = "0"; # Retry auth indefinitely

        # IPv6 configuration
        "ipv6.method" = "auto";
        "ipv6.addr-gen-mode" = "stable-privacy";

        # Connection priority: Prefer ethernet over WiFi
        "ethernet.auto-negotiate" = "yes";
        "wifi.autoconnect-priority" = "-1"; # Lower priority for WiFi
      };

      # Device-specific settings for better stability
      device = {
        # Disable WiFi powersave that can cause disconnections
        "wifi.powersave" = "2"; # 2 = disable powersave
        "wifi.wake-on-wlan" = "0x0"; # Disable wake-on-WLAN

        # Ethernet settings
        "ethernet.wake-on-lan" = "0x0"; # Disable wake-on-LAN for stability
      };

      # WiFi-specific settings for stability
      "802-11-wireless" = {
        "powersave" = "2"; # Disable powersave mode
        "mac-address-randomization" = "never";
      };
    };
  };

  # Explicit firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 5173 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

# Removed complex udev rules - letting NixOS handle power management with defaults

  # Disable systemd services that are affecting the boot time
  systemd.services = {
    NetworkManager-wait-online.enable = true;
    plymouth-quit-wait.enable = false;
  };

  # Simple suspend configuration - let NixOS handle the details
  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
  };


  # Additional systemd network-related configurations
  systemd.network.wait-online = {
    timeout = 30;  # Increase timeout for better reliability
    anyInterface = true;  # Don't wait for all interfaces
  };

  # Timezone (Sweden)
  time.timeZone = "Europe/Stockholm";

  # Internationalization: English UI + Swedish formats
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "sv_SE.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LC_TIME = "sv_SE.UTF-8";
      LC_MONETARY = "sv_SE.UTF-8";
      LC_MEASUREMENT = "sv_SE.UTF-8";
    };
  };

  # Enables support for Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Required for WebAuthn/passkeys cross-device (caBLE) via BLE
      };
    };
  };

  # Enable Thunderbolt/USB4 support for USB-C hubs and docks
  services.hardware.bolt.enable = true;

  # Enable UPower for battery/power management (required by HyprDynamicMonitors)
  services.upower.enable = true;

  # Input settings
  services.libinput = {
    enable = true;
    touchpad = {
      scrollMethod = "twofinger";
      tapping = true;
      accelSpeed = "-0.3";
      # Reduce scroll sensitivity with custom pixel distance (default ~15)
      additionalOptions = ''
        Option "ScrollPixelDistance" "200"
      '';
    };
  };

  # X server keyboard: US + SE, Alt+Shift to toggle
  services.xserver = {
    xkb = {
      layout = "us,se";
      options = "grp:alt_shift_toggle";
      variant = "";
    };
    excludePackages = with pkgs; [xterm];
  };

  # Wayland environment variables for Intel graphics
  environment.variables = {
    NIXOS_OZONE_WL = "1"; # Enable Wayland support in Chromium/Electron apps
    # Using Intel graphics - NVIDIA variables removed
    LIBVA_DRIVER_NAME = "iHD"; # Hardware video acceleration via Intel
    VDPAU_DRIVER = "va_gl"; # Video decode acceleration via VA-API
  };

  # PATH configuration
  environment.localBinInPath = true;

  # Enable CUPS printing
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    gutenprint  # Generic printer drivers
    gutenprintBin  # Gutenprint utilities
  ];
  # Enable auto-discovery of network printers
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable devmon for device management
  services.devmon.enable = true;

  # Modern audio system (replaces PulseAudio)
  services.pulseaudio.enable = false; # Disable legacy PulseAudio
  security.rtkit.enable = true; # Real-time scheduling for audio
  services.pipewire = {
    enable = true; # Enable PipeWire audio server
    alsa.enable = true; # ALSA compatibility layer
    alsa.support32Bit = true; # 32-bit app audio support
    pulse.enable = true; # PulseAudio compatibility
    jack.enable = true; # JACK audio system support
    # RAOP (AirPlay) discovery for streaming to AirPlay devices (e.g., Denon AVR)
    extraConfig.pipewire-pulse."raop-discover" = {
      "pulse.cmd" = [
        { cmd = "load-module"; args = "module-raop-discover"; }
      ];
    };
  };

  # Enable flatpak service
  services.flatpak.enable = true;

  # User account configuration
  users.users.${userConfig.name} = {
    description = userConfig.fullName;
    extraGroups = [
      "networkmanager" # Network configuration access
      "wheel" # Sudo privileges
      "fuse" # Filesystem mounting permissions
      "docker" # Docker daemon access
      "audio" # Direct audio device access and PAM limits
      "bluetooth" # Bluetooth device access (needed for WebAuthn/passkeys)
    ];
    isNormalUser = true; # Standard user account (not system)
    shell = pkgs.zsh; # Default shell
  };

  # Set User's avatar
  system.activationScripts.script.text = ''
    mkdir -p /var/lib/AccountsService/{icons,users}
    cp ${userConfig.avatar} /var/lib/AccountsService/icons/${userConfig.name}

    touch /var/lib/AccountsService/users/${userConfig.name}

    if ! grep -q "^Icon=" /var/lib/AccountsService/users/${userConfig.name}; then
      if ! grep -q "^\[User\]" /var/lib/AccountsService/users/${userConfig.name}; then
        echo "[User]" >> /var/lib/AccountsService/users/${userConfig.name}
      fi
      echo "Icon=/var/lib/AccountsService/icons/${userConfig.name}" >> /var/lib/AccountsService/users/${userConfig.name}
    fi
  '';

  # Passwordless sudo
  security.sudo.wheelNeedsPassword = false;

  # Essential system packages
  environment.systemPackages = with pkgs; [
    fuse3 # Filesystem in userspace library
    gcc # GNU C compiler
    glib # Low-level system library
    gnumake # GNU make build tool
    killall # Process termination utility
    mesa # Open-source OpenGL implementation
    ethtool # Ethernet device configuration utility
    usbutils # USB device utilities (lsusb)
    socat # Socket communication tool for Hyprland IPC
    sops # Secrets management with age encryption
    just # Modern task runner (replacement for make)
    bitwarden-cli # Password manager CLI for secrets management
    wireguard-tools # WireGuard VPN utilities (wg, wg-quick) for NetworkManager integration
    openssl # Cryptography toolkit (TLS, certificates, key generation)
    unixtools.xxd # Hex dump / reverse hex dump utility
  ];

  # Enable firmware for better hardware support
  hardware.enableRedistributableFirmware = true;

  # Docker containerization platform
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Allow user-level mounting
  programs.fuse.userAllowOther = true;

  # Enable xwayland
  programs.xwayland.enable = true;

  # Zsh configuration
  programs.zsh.enable = true;
  environment.pathsToLink = ["/share/zsh"];

  # System fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Programming font with icons
    nerd-fonts.meslo-lg # Terminal font with powerline support
    roboto # Modern sans-serif UI font
  ];

  # Additional services
  services.locate.enable = true;

  # OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      AllowUsers = [ "daniel" ];
    };
  };
}
