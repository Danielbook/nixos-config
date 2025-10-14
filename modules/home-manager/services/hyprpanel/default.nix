{...}: {
  # Enable HyprPanel via home-manager module
  # HyprPanel includes built-in notifications, so no separate daemon needed
  programs.hyprpanel = {
    enable = true;

    settings = {
      bar.launcher.autoDetectIcon = true;
      theme.bar.floating = true;
      theme.bar.transparent = true;

      # Font configuration - use Nerd Font for icons
      theme.font.name = "JetBrainsMono Nerd Font";
      theme.font.size = "16px";

      # Notification positioning - top center (stays within bounds)
      theme.notification.position = "top";
      theme.notification.monitor = 0;

      # Bar layout - show current language with systray, remove kbinput (not working)
      bar.layouts = {
        "0" = {
          left = ["dashboard" "workspaces" "windowtitle"];
          middle = ["media"];
          right = ["systray" "volume" "network" "bluetooth" "battery" "clock" "notifications"];
        };
      };

      # Dashboard shortcuts configuration (using Nerd Font icons)
      menus.dashboard.shortcuts.left.shortcut1.command = "firefox";
      menus.dashboard.shortcuts.left.shortcut1.tooltip = "Firefox";
      menus.dashboard.shortcuts.left.shortcut1.icon = "󰈹";

      menus.dashboard.shortcuts.left.shortcut2.command = "ghostty";
      menus.dashboard.shortcuts.left.shortcut2.tooltip = "Terminal";
      menus.dashboard.shortcuts.left.shortcut2.icon = "";

      menus.dashboard.shortcuts.left.shortcut3.command = "fuzzel";
      menus.dashboard.shortcuts.left.shortcut3.tooltip = "App Launcher";
      menus.dashboard.shortcuts.left.shortcut3.icon = "󰀻";

      # Clock configuration - 24-hour format
      menus.clock.time.military = true;

      # Weather configuration - Motala, Sweden
      menus.clock.weather.location = "Motala, Sweden";
      menus.clock.weather.unit = "metric";
    };
  };
}
