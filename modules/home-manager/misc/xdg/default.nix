{
  config,
  lib,
  pkgs,
  ...
}: {
  xdg = {
    enable = true;

    mimeApps = {
      enable = true;

      # Use new defaultApplicationPackages API (replaces deprecated lib.xdg.mimeAssociations)
      # Note: google-chrome is installed via host-specific config with custom flags
      defaultApplicationPackages = [
        pkgs.gnome-text-editor
        pkgs.loupe
        pkgs.totem
      ];

      defaultApplications = {
        "text/html" = "google-chrome.desktop";
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/https" = "google-chrome.desktop";
        "x-scheme-handler/about" = "google-chrome.desktop";
        "x-scheme-handler/unknown" = "google-chrome.desktop";
      };
    };

    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
