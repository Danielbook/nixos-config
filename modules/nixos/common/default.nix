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
    kernelPackages = pkgs.linuxPackages;      # Use latest stable kernel
    consoleLogLevel = 0;                      # Minimal boot messages
    initrd.verbose = false;                   # Quiet initramfs
    kernelParams = [
      "quiet"                                 # Reduce kernel messages
      "splash"                                # Show boot splash
      "rd.udev.log_level=3"                  # Minimal udev logging
    ];
    loader.efi.canTouchEfiVariables = true;  # Allow EFI variable modification
    loader.systemd-boot = {
      enable = true;                          # Use systemd-boot bootloader
      configurationLimit = 10;               # Keep last 10 generations
    };
    loader.timeout = 10;                     # Boot menu timeout (seconds)
    plymouth.enable = true;                   # Graphical boot splash

    # v4l (virtual camera) module settings
    #kernelModules = ["v4l2loopback"];
    #extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
    #extraModprobeConfig = ''
    #  options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    #'';
  };

  # Networking
  networking.networkmanager.enable = true;

  # Disable systemd services that are affecting the boot time
  systemd.services = {
    NetworkManager-wait-online.enable = false;
    plymouth-quit-wait.enable = false;
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

  # Wayland/NVIDIA compatibility environment variables
  environment.variables = {
    NIXOS_OZONE_WL = "1";                     # Enable Wayland support in Chromium/Electron apps
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";     # Force GLX to use NVIDIA drivers
    WLR_NO_HARDWARE_CURSORS = "1";           # Fix cursor issues on NVIDIA (prevents black screens)
    LIBVA_DRIVER_NAME = "nvidia";             # Hardware video acceleration via NVIDIA
    VDPAU_DRIVER = "nvidia";                  # Video decode acceleration via NVIDIA
  };

  # PATH configuration
  environment.localBinInPath = true;

  # Disable CUPS printing
  services.printing.enable = false;

  # Enable devmon for device management
  services.devmon.enable = true;

  # Modern audio system (replaces PulseAudio)
  services.pulseaudio.enable = false;       # Disable legacy PulseAudio
  security.rtkit.enable = true;             # Real-time scheduling for audio
  services.pipewire = {
    enable = true;                          # Enable PipeWire audio server
    alsa.enable = true;                     # ALSA compatibility layer
    alsa.support32Bit = true;              # 32-bit app audio support
    pulse.enable = true;                    # PulseAudio compatibility
    jack.enable = true;                     # JACK audio system support
  };

  # Enable flatpak service
  services.flatpak.enable = true;

  # User account configuration
  users.users.${userConfig.name} = {
    description = userConfig.fullName;
    extraGroups = [
      "networkmanager"     # Network configuration access
      "wheel"              # Sudo privileges
      "fuse"               # Filesystem mounting permissions
      "docker"             # Docker daemon access
    ];
    isNormalUser = true;   # Standard user account (not system)
    shell = pkgs.zsh;      # Default shell
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
    fuse3       # Filesystem in userspace library
    gcc         # GNU C compiler
    glib        # Low-level system library
    gnumake     # GNU make build tool
    killall     # Process termination utility
    mesa        # Open-source OpenGL implementation
  ];

  # Docker containerization platform
  virtualisation.docker.enable = true;                    # Enable Docker daemon
  virtualisation.docker.rootless.enable = true;          # Rootless Docker for security
  virtualisation.docker.rootless.setSocketVariable = true; # Set DOCKER_HOST variable

  # Allow user-level mounting
  programs.fuse.userAllowOther = true;

  # Enable xwayland
  programs.xwayland.enable = true;

  # Zsh configuration
  programs.zsh.enable = true;

  # System fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono   # Programming font with icons
    nerd-fonts.meslo-lg         # Terminal font with powerline support
    roboto                      # Modern sans-serif UI font
  ];

  # Additional services
  services.locate.enable = true;

  # OpenSSH daemon
  services.openssh.enable = true;
}
