{pkgs, ...}: {
  # Albert package
  home.packages = [pkgs.albert];

  # Make the launcher run Albert via XCB (Wayland stays default for everything else)
  xdg.desktopEntries.albert = {
    name = "Albert";
    genericName = "Launcher";
    # Important bit: inject the env var just for Albert
    exec = "env QT_QPA_PLATFORM=xcb ${pkgs.albert}/bin/albert %U";
    icon = "albert";
    terminal = false;
    categories = ["Utility"];
    # Optional: add Keywords, StartupWMClass, etc., if you want
  };

  # Source albert configuration from the home-manager store
  xdg.configFile."albert/config".text = ''
    [General]
    frontend=widgetsboxmodel-ng
    showTray=false
    telemetry=false

    [applications]
    enabled=true
    global_handler_enabled=true

    [chromium]
    enabled=true
    fuzzy=false
    global_handler_enabled=false
    trigger=bm

    [clipboard]
    enabled=true
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

    [widgetsboxmodel-ng]
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
}
