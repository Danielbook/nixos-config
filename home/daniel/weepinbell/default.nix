{
  nhModules,
  pkgs,
  ...
}: {
  imports = [
    "${nhModules}/common"
    "${nhModules}/desktop/hyprland"
  ];

  # Enable home-manager
  programs.home-manager = {
    enable = true;
  };

  # Essential packages for this machine
  home.packages = with pkgs; [
    bitwarden # Password manager
    google-chrome # Web browser
    nodejs_20 # Node.js runtime
    nixos-anywhere # Remote NixOS deployment tool
    # spotify                           # Moved to Flatpak for better Wayland support
    thunderbird # Email client
  ];

  # Stop the CLI’s auto-updater; Nix will handle upgrades.
  home.sessionVariables.DISABLE_AUTOUPDATER = "1";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/chrome" = ["chromium-browser.desktop"];
      "x-scheme-handler/ftp" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "application/pdf" = "firefox.desktop";
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
