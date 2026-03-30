{
  lib,
  nhModules,
  pkgs,
  ...
}: {
  imports = [
    "${nhModules}/misc/gtk"
    "${nhModules}/misc/qt"
    "${nhModules}/misc/wallpaper"
    "${nhModules}/misc/xdg"
    "${nhModules}/services/cliphist"
    "${nhModules}/services/noctalia"
    "${nhModules}/services/awww"
    "${nhModules}/services/hypridle"
    "${nhModules}/services/raop-volume-guard"
  ];

  # Consistent cursor theme across all applications.
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.yaru-theme;
    name = "Yaru";
    size = 24;
  };

  # Source hyprland config from the home-manager store
  xdg.configFile = {
    "hypr/hyprland.conf" = {
      source = ./hyprland.conf;
    };

  };

  # Resume lockscreen recovery script for suspend/resume
  home.file.".local/bin/resume-lockscreen" = {
    source = ./resume-lockscreen.sh;
    executable = true;
  };

  # Toggle mirror script for presentations/conference rooms
  home.file.".local/bin/toggle-mirror" = {
    text = ''
      #!/usr/bin/env bash
      # Toggle mirror mode for presentations/conference rooms
      # Mirrors external monitor to laptop display or restores normal mode

      LAPTOP="desc:Samsung Display Corp. 0x415D"

      # Get all external monitors (not the laptop)
      EXTERNALS=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.description != "Samsung Display Corp. 0x415D") | .name')

      if [ -z "$EXTERNALS" ]; then
          ${pkgs.libnotify}/bin/notify-send "Mirror Toggle" "No external monitors detected"
          exit 0
      fi

      # Check if any external is currently mirroring
      CURRENT_MIRROR=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.description != "Samsung Display Corp. 0x415D") | .mirrorOf')

      if [ "$CURRENT_MIRROR" != "" ] && [ "$CURRENT_MIRROR" != "none" ]; then
          # Currently mirroring - restore normal mode
          for monitor in $EXTERNALS; do
              ${pkgs.hyprland}/bin/hyprctl keyword monitor "$monitor,preferred,auto,1"
          done
          ${pkgs.libnotify}/bin/notify-send "Mirror Mode" "Disabled - restored normal display"
      else
          # Not mirroring - enable mirror mode
          for monitor in $EXTERNALS; do
              ${pkgs.hyprland}/bin/hyprctl keyword monitor "$monitor,preferred,auto,1,mirror,$LAPTOP"
          done
          ${pkgs.libnotify}/bin/notify-send "Mirror Mode" "Enabled - mirroring to external display(s)"
      fi
    '';
    executable = true;
  };

  dconf.settings = {
    "org/blueman/general" = {
      "plugin-list" = lib.mkForce ["!StatusNotifierItem"];
    };

    "org/blueman/plugins/powermanager" = {
      "auto-power-on" = true;
    };

    "org/gnome/calculator" = {
      "accuracy" = 9;
      "angle-units" = "degrees";
      "base" = 10;
      "button-mode" = "basic";
      "number-format" = "automatic";
      "show-thousands" = false;
      "show-zeroes" = false;
      "source-currency" = "";
      "source-units" = "degree";
      "target-currency" = "";
      "target-units" = "radian";
      "window-maximized" = false;
    };

    "org/gnome/desktop/interface" = {
      "color-scheme" = "prefer-dark";
      "cursor-theme" = "Yaru";
      "font-name" = "Roboto 11";
      "icon-theme" = "Tela-circle-dark";
    };

    "org/gnome/desktop/wm/preferences" = {
      "button-layout" = lib.mkForce "";
    };

    "org/gnome/nautilus/preferences" = {
      "default-folder-viewer" = "list-view";
      "migrated-gtk-settings" = true;
      "search-filter-time-type" = "last_modified";
      "search-view" = "list-view";
    };

    "org/gnome/nm-applet" = {
      "disable-connected-notifications" = true;
      "disable-vpn-notifications" = true;
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      "show-hidden" = true;
    };

    "org/gtk/settings/file-chooser" = {
      "date-format" = "regular";
      "location-mode" = "path-bar";
      "show-hidden" = true;
      "show-size-column" = true;
      "show-type-column" = true;
      "sort-column" = "name";
      "sort-directories-first" = false;
      "sort-order" = "ascending";
      "type-format" = "category";
      "view-type" = "list";
    };
  };
}
