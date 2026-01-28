{pkgs, ...}: {
  # Fuzzel application launcher - Wayland-native and stable replacement for Albert
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.ghostty}/bin/ghostty -e";
        layer = "overlay";
        font = "JetBrainsMono Nerd Font:size=12";
        dpi-aware = "no";
        width = 35;
        lines = 15;
        horizontal-pad = 20;
        vertical-pad = 8;
        inner-pad = 5;
        prompt = "❯ ";
        icon-theme = "Papirus-Dark";
        show-actions = "yes";
        exit-on-keyboard-focus-loss = "no";
      };

      # Catppuccin Macchiato theme to match your system
      colors = {
        background = "24273add";
        text = "cad3f5ff";
        match = "ed8796ff";
        selection = "5b6078dd";
        selection-text = "cad3f5ff";
        selection-match = "f5a97fff";
        border = "b4befeff";
      };

      border = {
        width = 2;
        radius = 8;
      };

      dmenu = {
        exit-immediately-if-empty = "no";
      };
    };
  };

  # Custom script for clipboard integration
  home.packages = with pkgs; [
    cliphist  # Required for clipboard functionality
  ];

  # Script for clipboard integration with fuzzel
  xdg.configFile."fuzzel/fuzzel-clipboard.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Fuzzel clipboard integration script
      cliphist list | fuzzel --dmenu --prompt "📋 " | cliphist decode | wl-copy
    '';
    executable = true;
  };

  # Desktop entries for power management that appear in fuzzel
  xdg.desktopEntries = {
    lock-screen = {
      name = "Lock Screen";
      comment = "Lock the screen";
      exec = "noctalia-shell ipc call lockScreen lock";
      icon = "system-lock-screen";
      categories = [ "System" ];
      noDisplay = false;
    };


    reboot-system = {
      name = "Reboot";
      comment = "Restart the computer";
      exec = "systemctl reboot";
      icon = "system-reboot";
      categories = [ "System" ];
      noDisplay = false;
    };

    shutdown-system = {
      name = "Shutdown";
      comment = "Power off the computer";
      exec = "systemctl poweroff";
      icon = "system-shutdown";
      categories = [ "System" ];
      noDisplay = false;
    };
  };
}