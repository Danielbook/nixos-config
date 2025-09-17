{pkgs, ...}: {
  # SwayNC notification center for Wayland
  home.packages = [pkgs.swaynotificationcenter];

  # SwayNC systemd service
  systemd.user.services.swaync = {
    Unit = {
      Description = "SwayNC notification daemon";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      ExecReload = "${pkgs.swaynotificationcenter}/bin/swaync-client --reload-config";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  # SwayNC configuration files
  xdg.configFile = {
    "swaync/config.json".text = ''
      {
        "$schema": "/etc/xdg/swaync/configSchema.json",
        "positionX": "right",
        "positionY": "top",
        "layer": "overlay",
        "control-center-layer": "top",
        "layer-shell": true,
        "cssPriority": "application",
        "control-center-margin-top": 0,
        "control-center-margin-bottom": 0,
        "control-center-margin-right": 0,
        "control-center-margin-left": 0,
        "notification-2fa-action": true,
        "notification-inline-replies": false,
        "notification-icon-size": 64,
        "notification-body-image-height": 100,
        "notification-body-image-width": 200,
        "timeout": 10,
        "timeout-low": 5,
        "timeout-critical": 0,
        "fit-to-screen": true,
        "control-center-width": 500,
        "control-center-height": 600,
        "notification-window-width": 500,
        "keyboard-shortcuts": true,
        "image-visibility": "when-available",
        "transition-time": 200,
        "hide-on-clear": false,
        "hide-on-action": true,
        "script-fail-notify": true
      }
    '';

    "swaync/style.css".text = ''
      /* SwayNC Catppuccin Theme */
      .notification-row {
        outline: none;
      }
      
      .notification {
        border-radius: 12px;
        margin: 6px 12px;
        box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.3), 0 1px 3px 1px rgba(0, 0, 0, 0.7);
        padding: 0;
      }
      
      .control-center {
        border-radius: 12px;
        margin: 12px;
        background-color: #24273a;
        border: 1px solid #363a4f;
        box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.3), 0 1px 3px 1px rgba(0, 0, 0, 0.7);
      }
    '';
  };
}
