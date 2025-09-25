{
  config,
  pkgs,
  ...
}: {
  # Swww wallpaper daemon service
  systemd.user.services.swww-daemon = {
    Unit = {
      Description = "Swww wallpaper daemon";
      PartOf = ["hyprland-session.target"];
      After = ["hyprland-session.target"];
      Requisite = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Restart = "on-failure";
      RestartSec = "2s";
      Environment = "WAYLAND_DISPLAY=wayland-1";
    };
    Install.WantedBy = ["hyprland-session.target"];
  };

  # Set initial wallpaper
  systemd.user.services.swww-wallpaper = {
    Unit = {
      Description = "Set wallpaper with swww";
      After = ["swww-daemon.service"];
      Requires = ["swww-daemon.service"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.swww}/bin/swww img ${config.wallpaper}";
      RemainAfterExit = true;
      Environment = "WAYLAND_DISPLAY=wayland-1";
    };
    Install.WantedBy = ["hyprland-session.target"];
  };
}