{
  lib,
  pkgs,
  ...
}:
{
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
        "text/html" = lib.mkDefault "google-chrome.desktop";
        "x-scheme-handler/http" = lib.mkDefault "google-chrome.desktop";
        "x-scheme-handler/https" = lib.mkDefault "google-chrome.desktop";
        "x-scheme-handler/about" = lib.mkDefault "google-chrome.desktop";
        "x-scheme-handler/unknown" = lib.mkDefault "google-chrome.desktop";
      };
    };

    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = false;
    };
  };
}
