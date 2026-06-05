{
  userConfig,
  pkgs,
  ...
}:
let
  # Single source of truth: ethernet connected -> WiFi off, otherwise WiFi on.
  # Called by both the NM dispatcher (link up/down) and the resume hook, since a
  # resume from suspend/hibernate does not reliably replay link events.
  reconcileWifi = pkgs.writeShellApplication {
    name = "reconcile-wifi";
    runtimeInputs = [
      pkgs.networkmanager
      pkgs.util-linux
      pkgs.gnugrep
    ];
    text = ''
      if nmcli -t -f TYPE,STATE device status | grep -q '^ethernet:connected$'; then
        nmcli radio wifi off
        logger "reconcile-wifi: WiFi off (ethernet connected)"
      else
        nmcli radio wifi on
        logger "reconcile-wifi: WiFi on (no ethernet connected)"
      fi
    '';
  };
in
{
  # Boot cosmetics (graphical splash)
  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "rd.udev.log_level=3"
    ];
    plymouth.enable = true;
  };

  # Disable plymouth-quit-wait to improve boot time
  systemd.services.plymouth-quit-wait.enable = false;

  # NetworkManager desktop-specific settings
  networking.networkmanager = {
    # Automatically prefer ethernet over WiFi
    dispatcherScripts = [
      {
        source = pkgs.writeText "prefer-ethernet" ''
          #!/bin/sh
          # On ethernet link up/down, reconcile WiFi state.
          interface="$1"
          action="$2"
          case "$interface" in
            eth*|en*)
              case "$action" in
                up | down) ${reconcileWifi}/bin/reconcile-wifi ;;
              esac
              ;;
          esac
        '';
        type = "basic";
      }
    ];

    # WiFi and connection stability settings
    settings = {
      main = {
        "wifi.scan-rand-mac-address" = "no";
      };

      connection = {
        "wifi.autoconnect-priority" = "-1";
      };

      device = {
        "wifi.powersave" = "2";
        "wifi.wake-on-wlan" = "0x0";
      };

      "802-11-wireless" = {
        "powersave" = "2";
        "mac-address-randomization" = "never";
      };
    };
  };

  # Reconcile WiFi/ethernet on resume from suspend/hibernate. NM link events are
  # not reliably replayed across a resume (e.g. ethernet unplugged while asleep),
  # so re-run the same logic the dispatcher uses. Brief sleep lets NM settle.
  powerManagement.resumeCommands = ''
    ${pkgs.coreutils}/bin/sleep 2
    ${reconcileWifi}/bin/reconcile-wifi
  '';

  # Desktop-specific firewall ports
  networking.firewall = {
    allowedTCPPorts = [
      5173
      53317
    ];
    allowedUDPPorts = [ 53317 ];
  };

  # Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Required for WebAuthn/passkeys cross-device (caBLE) via BLE
      };
    };
  };

  # Thunderbolt/USB4 support for USB-C hubs and docks
  services.hardware.bolt.enable = true;

  # Battery/power management (required by HyprDynamicMonitors)
  services.upower.enable = true;

  # Touchpad input settings
  services.libinput = {
    enable = true;
    touchpad = {
      scrollMethod = "twofinger";
      tapping = true;
      accelSpeed = "-0.3";
      additionalOptions = ''
        Option "ScrollPixelDistance" "200"
      '';
    };
  };

  # Keyboard layout: US + SE, Alt+Shift to toggle
  services.xserver = {
    xkb = {
      layout = "us,se";
      options = "grp:alt_shift_toggle";
      variant = "";
    };
    excludePackages = with pkgs; [ xterm ];
  };

  # Wayland session env vars. GPU-specific vars (LIBVA_DRIVER_NAME,
  # GBM_BACKEND, VDPAU_DRIVER, __GLX_VENDOR_LIBRARY_NAME) live in the
  # per-host graphics module so they can track the active GPU.
  environment.variables = {
    NIXOS_OZONE_WL = "1";
  };

  # Xwayland support
  programs.xwayland.enable = true;

  # CUPS printing + network printer discovery
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    gutenprintBin
  ];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Device management
  services.devmon.enable = true;

  # Audio: PipeWire (replaces PulseAudio)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    # RAOP (AirPlay) discovery for streaming to AirPlay devices
    extraConfig.pipewire-pulse."raop-discover" = {
      "pulse.cmd" = [
        {
          cmd = "load-module";
          args = "module-raop-discover";
        }
      ];
    };
  };

  # Flatpak
  services.flatpak.enable = true;

  # Suspend/lid configuration
  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
  };

  # Desktop-specific user groups
  users.users.${userConfig.name}.extraGroups = [
    "fuse"
    "audio"
    "bluetooth"
  ];

  # User avatar (AccountsService for display managers)
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

  # Desktop-specific system packages
  environment.systemPackages = with pkgs; [
    mesa
    socat # Hyprland IPC
  ];

  # System fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    roboto
  ];
}
