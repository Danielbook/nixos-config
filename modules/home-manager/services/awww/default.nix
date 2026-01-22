{
  config,
  pkgs,
  inputs,
  ...
}: let
  swwwitch = inputs.swwwitch.packages.${pkgs.stdenv.hostPlatform.system}.default;
  awww = inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  # Make awww available in PATH
  home.packages = [ awww ];

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

  # Kill swww-daemon if HyprPanel starts it (we use awww instead)
  systemd.user.services.kill-swww-daemon = {
    Unit = {
      Description = "Kill swww-daemon to prevent conflict with awww";
      After = ["awww-daemon.service" "hyprpanel.service"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.procps}/bin/pkill swww-daemon || true'";
      RemainAfterExit = false;
    };
    Install.WantedBy = ["hyprland-session.target"];
  };

  # Set initial wallpaper
  systemd.user.services.awww-wallpaper = {
    Unit = {
      Description = "Set wallpaper with swwwitch";
      After = ["awww-daemon.service" "kill-swww-daemon.service"];
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