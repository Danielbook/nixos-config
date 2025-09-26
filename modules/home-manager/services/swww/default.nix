{
  config,
  pkgs,
  ...
}: {
  # Swww wallpaper daemon service
  systemd.user.services.swww-daemon = {
    Unit = {
      Description = "Swww wallpaper daemon";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Restart = "on-failure";
      RestartSec = "2s";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  # Set initial wallpaper
  systemd.user.services.swww-wallpaper = {
    Unit = {
      Description = "Set wallpaper with swww";
      After = ["swww-daemon.service"];
      Requires = ["swww-daemon.service"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.swww}/bin/swww img ${config.wallpaper}";
      RemainAfterExit = true;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}