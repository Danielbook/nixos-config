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
    overlays = [
      outputs.overlays.stable-packages
    ];

    config = {
      allowUnfree = true;
    };
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
      "usbcore.autosuspend=-1" # Disable USB autosuspend globally as backup
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

  # Comprehensive power management and wake configuration for network stability
  services.udev.extraRules = ''
    # === USB ETHERNET ADAPTERS ===
    # Disable USB autosuspend for ALL ethernet adapter drivers
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="r8152", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="asix", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="ax88179_178a", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="cdc_ether", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="dm9601", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="smsc95xx", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="rtl8152", ATTR{power/autosuspend}="-1"
    
    # Disable USB autosuspend for ALL devices with ethernet class
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="02", ATTR{bInterfaceSubClass}=="06", ATTR{power/autosuspend}="-1"
    
    # Specific USB ethernet adapters by vendor/product ID
    # Realtek RTL8153/RTL8152 family
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8153", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8152", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8150", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8051", ATTR{power/autosuspend}="-1"
    # ASIX AX88179/178A family
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0b95", ATTR{idProduct}=="1790", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0b95", ATTR{idProduct}=="178a", ATTR{power/autosuspend}="-1"
    
    # === WiFi ADAPTERS ===
    # Disable USB autosuspend for WiFi adapters
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="rtl8xxxu", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="rtw88_8822bu", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="mt76x0u", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="mt76x2u", ATTR{power/autosuspend}="-1"
    
    # === NETWORK INTERFACES ===
    # Disable runtime power management for ALL network interfaces
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth*", ATTR{device/power/control}="on"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="enp*", ATTR{device/power/control}="on"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="eno*", ATTR{device/power/control}="on"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="ens*", ATTR{device/power/control}="on"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", ATTR{device/power/control}="on"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlo*", ATTR{device/power/control}="on"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlp*", ATTR{device/power/control}="on"
    
    # === PCI NETWORK DEVICES ===
    # Disable power management for PCI network devices
    ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x020000", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x028000", ATTR{power/control}="on"
    
    # === BLUETOOTH ===
    # Disable USB autosuspend for Bluetooth adapters (can affect WiFi coexistence)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="e0", ATTR{bInterfaceSubClass}=="01", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0026", ATTR{power/autosuspend}="-1"
    
    # === INPUT DEVICES (Keep wake capability) ===
    # Enable USB wake for keyboards and mice (allow wake from suspend)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", ATTR{bInterfaceSubClass}=="01", ATTR{bInterfaceProtocol}=="01", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", ATTR{bInterfaceSubClass}=="01", ATTR{bInterfaceProtocol}=="02", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usbhid", ATTR{power/wakeup}="enabled"

    # === PROBLEMATIC DEVICES ===
    # Disable wakeup for devices that can cause immediate wake from suspend
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", ATTR{power/wakeup}="disabled"
    
    # Disable autosuspend for USB hubs (can cause network device disconnections)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", ATTR{power/autosuspend}="-1"
  '';

  # Disable systemd services that are affecting the boot time
  systemd.services = {
    NetworkManager-wait-online.enable = true;
    plymouth-quit-wait.enable = false;
  };

  # Systemd sleep configuration for better suspend/resume reliability
  systemd.sleep.extraConfig = ''
    # Suspend-to-RAM configuration
    HibernateDelaySec=30min
    SuspendEstimationSec=5s
  '';
  
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
  };

  # Input settings
  services.libinput.enable = true;

  # X server keyboard: US + SE, Alt+Shift to toggle
  services.xserver = {
    xkb.layout = "us,se";
    xkb.options = "grp:alt_shift_toggle";
    xkb.variant = "";
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

  # Disable CUPS printing
  services.printing.enable = false;

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
  ];

  # Enable firmware for better hardware support
  hardware.enableRedistributableFirmware = true;

  # Docker containerization platform
  virtualisation.docker.enable = true; # Enable Docker daemon
  virtualisation.docker.rootless.enable = true; # Rootless Docker for security
  virtualisation.docker.rootless.setSocketVariable = true; # Set DOCKER_HOST variable

  # Allow user-level mounting
  programs.fuse.userAllowOther = true;

  # Enable xwayland
  programs.xwayland.enable = true;

  # Zsh configuration
  programs.zsh.enable = true;

  # System fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Programming font with icons
    nerd-fonts.meslo-lg # Terminal font with powerline support
    roboto # Modern sans-serif UI font
  ];

  # Additional services
  services.locate.enable = true;

  # OpenSSH daemon
  services.openssh.enable = true;
}
