{pkgs, ...}: {
  # Albert application launcher package
  home.packages = [pkgs.albert];

  # Desktop entry for Albert launcher (native Wayland for stability)
  xdg.desktopEntries.albert = {
    name = "Albert";
    genericName = "Application Launcher";
    exec = "${pkgs.albert}/bin/albert %U";     # Native Wayland (no XCB forcing)
    icon = "albert";
    terminal = false;
    categories = ["Utility"];
  };

  # Albert configuration file
  xdg.configFile."albert/config".text = ''
    [General]
    frontend=widgetsboxmodel              # Stable frontend (not -ng)
    showTray=false                        # Hide system tray icon
    telemetry=false                       # Disable telemetry

    [applications]
    enabled=true                          # Enable application search
    global_handler_enabled=true

    [chromium]
    enabled=false                         # Disabled (problematic plugin)
    fuzzy=false
    global_handler_enabled=false
    trigger=bm

    [clipboard]
    enabled=false                         # Disabled (causes crashes)
    persistent=true
    trigger=clipboard

    [debug]
    enabled=false

    [path]
    enabled=false

    [system]
    command_lock=loginctl lock-session
    command_logout="[ \"$DESKTOP_SESSION\" = \"hyprland\" ] && { hyprctl -j clients 2>/dev/null | jq -j '.[] | \"dispatch closewindow address:\\(.address); \"' | xargs -r hyprctl --batch 2>/dev/null; } || [ \"$DESKTOP_SESSION\" = \"plasma\" ] && kdotool search '.*' windowclose %@ || true"
    command_poweroff=systemctl poweroff -i
    command_reboot=systemctl reboot -i
    enabled=true
    logout_enabled=true
    title_logout=Quit All Applications
    title_poweroff=Shutdown
    trigger=sys

    [widgetsboxmodel]
    alwaysOnTop=true
    clearOnHide=true
    debug=false
    displayScrollbar=false
    followCursor=true
    hideOnFocusLoss=true
    historySearch=true
    itemCount=10
    quitOnClose=false
    showCentered=true
  '';

  # Systemd service for Albert with crash recovery
  systemd.user.services.albert = {
    Unit = {
      Description = "Albert application launcher";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.albert}/bin/albert";
      Restart = "on-failure";              # Restart if crashed
      RestartSec = 2;                      # Wait 2 seconds before restart
      Environment = [ "QT_QPA_PLATFORM=wayland" ];  # Force Wayland
    };
    Install.WantedBy = [ "default.target" ];
  };
}
