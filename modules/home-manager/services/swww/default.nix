{
  config,
  pkgs,
  ...
}: {
  # Create hyprland-session.target for Hyprland services
  systemd.user.targets.hyprland-session = {
    Unit = {
      Description = "Hyprland compositor session";
      Documentation = ["man:systemd.special(7)"];
      BindsTo = ["graphical-session.target"];
      Wants = ["graphical-session-pre.target"];
      After = ["graphical-session-pre.target"];
    };
  };
  # Swww wallpaper daemon service
  systemd.user.services.swww-daemon = {
    Unit = {
      Description = "Swww wallpaper daemon";
      PartOf = ["hyprland-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Restart = "on-failure";
      RestartSec = "2s";
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
    };
    Install.WantedBy = ["hyprland-session.target"];
  };
}