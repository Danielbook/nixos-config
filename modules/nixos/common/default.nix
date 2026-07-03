{
  inputs,
  outputs,
  lib,
  config,
  userConfig,
  pkgs,
  ...
}:
{
  # Nixpkgs configuration
  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "nvidia-x11"
        "nvidia-settings"
        "nvidia-persistenced"
        "nvidia-vaapi-driver"
        # closed kernel modules (open = false, tatooine/Pascal — open kernel
        # modules only support Turing+, and are dual MIT/GPL so don't need
        # this predicate at all).
        "nvidia-kernel-modules"
      ];
  };

  # Register flake inputs for nix commands
  nix.registry = lib.mapAttrs (_: flake: { inherit flake; }) (
    lib.filterAttrs (_: lib.isType "flake") inputs
  );

  # Add inputs to legacy channels
  nix.nixPath = [ "/etc/nix/path" ];
  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  # Nix settings
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };

  # Boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages;
    kernelParams = [
      # s2idle, not deep S3: deep S3 entry-hangs on this Optimus laptop after a few
      # suspend cycles (ACPI D-Notifier 0x11, open nvidia driver can't handle the
      # dGPU power-state handshake). s2idle = what Windows Modern Standby uses here.
      "mem_sleep_default=s2idle"

      # Network driver stability parameters
      "r8152.enable_aldps=0"
      "pci=pcie_bus_perf"
      "iwlwifi.power_save=0"
      "iwlwifi.uapsd_disable=1"
    ];
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 5;
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
    # Portable admin identity (private key lives in Bitwarden, served by its SSH
    # agent) — so any machine with Bitwarden unlocked can SSH in. Headless nodes
    # have no other login path (root disabled, password auth off), so this is the
    # only way in; keep at least one working key here.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILnp41RlfnpB82pkrQF6aI1VE5ULTY1+A2u3nNPBTO+b k3s-cluster-admin"
    ];
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
  environment.pathsToLink = [ "/share/zsh" ];

  # nix-ld: run dynamically linked executables built for generic Linux
  # (e.g. the native `claude` binary from the @anthropic-ai/claude-code npm package)
  programs.nix-ld.enable = true;

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
