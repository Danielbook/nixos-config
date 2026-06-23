{
  nhModules,
  pkgs,
  ...
}: {
  imports = [
    "${nhModules}/programs/alacritty"
    "${nhModules}/programs/brave"
    "${nhModules}/programs/firefox"
    "${nhModules}/programs/fuzzel"
    "${nhModules}/programs/ghostty"
    "${nhModules}/programs/kitty"
    "${nhModules}/programs/obs-studio"
    "${nhModules}/programs/vscode"
    "${nhModules}/programs/yabridge"
    "${nhModules}/services/easyeffects"
    "${nhModules}/services/flatpak"
    "${nhModules}/scripts/desktop"
  ];

  # Desktop-specific packages
  home.packages = with pkgs; [
    hyprshot
    prusa-slicer
    satty
    tesseract
    wl-clipboard
    xterm
  ];
}
