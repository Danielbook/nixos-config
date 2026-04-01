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
    kernelPackages = pkgs.linuxPackages;
    kernelParams = [
      "mem_sleep_default=deep"

      # Network driver stability parameters
      "r8152.enable_aldps=0"
      "pci=pcie_bus_perf"
      "iwlwifi.power_save=0"
      "iwlwifi.uapsd_disable=1"
    ];
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    loader.timeout = 10;
  };

  # Networking
  networking.networkmanager = {
    enable = true;

    settings = {
      main = {
        "dhcp" = "internal";
        "dns" = "default";
      };

      connection = {
        "connection.autoconnect-retries" = "0";
        "connection.auth-retries" = "0";
        "ipv6.method" = "auto";
        "ipv6.addr-gen-mode" = "stable-privacy";
        "ethernet.auto-negotiate" = "yes";
      };

      device = {
        "ethernet.wake-on-lan" = "0x0";
      };
    };
  };

  # Firewall
  networking.firewall.enable = true;

  # Wait for network
  systemd.services.NetworkManager-wait-online.enable = true;
  systemd.network.wait-online = {
    timeout = 30;
    anyInterface = true;
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

  # User account configuration
  users.users.${userConfig.name} = {
    description = userConfig.fullName;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    isNormalUser = true;
    shell = pkgs.zsh;
  };

  # Passwordless sudo
  security.sudo.wheelNeedsPassword = false;

  # Essential system packages
  environment.systemPackages = with pkgs; [
    fuse3
    glib
    killall
    ethtool
    usbutils
    sops
    just
    bitwarden-cli
    wireguard-tools
    openssl
    unixtools.xxd
  ];

  # PATH configuration
  environment.localBinInPath = true;

  # Enable firmware for better hardware support
  hardware.enableRedistributableFirmware = true;

  # Docker
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Allow user-level mounting
  programs.fuse.userAllowOther = true;

  # Zsh
  programs.zsh.enable = true;
  environment.pathsToLink = ["/share/zsh"];

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
