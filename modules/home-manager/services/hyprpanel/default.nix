{...}: {
  # Enable HyprPanel via home-manager module
  # HyprPanel includes built-in notifications, so no separate daemon needed
  programs.hyprpanel = {
    enable = true;

    # HyprPanel will be auto-started by systemd
    systemd.enable = true;

    # Override hyprland integration to use hyprpanel autostart
    hyprland.enable = true;
  };
}
