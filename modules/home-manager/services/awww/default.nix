{
  config,
  pkgs,
  inputs,
  ...
}: let
  swwwitch = inputs.swwwitch.packages.${pkgs.system}.default;
  awww = inputs.awww.packages.${pkgs.system}.default;
in {
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
  # awww wallpaper daemon service
  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww wallpaper daemon";
      PartOf = ["hyprland-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${awww}/bin/awww-daemon";
      Restart = "on-failure";
      RestartSec = "2s";
    };
    Install.WantedBy = ["hyprland-session.target"];
  };

  # Set initial wallpaper
  systemd.user.services.awww-wallpaper = {
    Unit = {
      Description = "Set wallpaper with swwwitch";
      After = ["awww-daemon.service"];
      Requires = ["awww-daemon.service"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${swwwitch}/bin/swwwitch --set ${config.wallpaper.default}";
      RemainAfterExit = true;
    };
    Install.WantedBy = ["hyprland-session.target"];
  };
}