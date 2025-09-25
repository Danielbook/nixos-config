{
  config,
  pkgs,
  ...
}: {
  # Hyprpaper configuration
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    splash = false
    preload = ${config.wallpaper}
    wallpaper = , ${config.wallpaper}
  '';

  # Hyprpaper service
  systemd.user.services.hyprpaper = {
    Unit = {
      Description = "Hyprpaper wallpaper daemon";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}