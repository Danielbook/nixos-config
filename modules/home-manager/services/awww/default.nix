{
  pkgs,
  inputs,
  ...
}: let
  awww = inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  # Make awww available in PATH (Noctalia uses it for wallpaper rendering)
  home.packages = [awww];

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

  # awww wallpaper daemon service (used by Noctalia for wallpaper rendering)
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
}