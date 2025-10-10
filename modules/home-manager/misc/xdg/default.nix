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
      defaultApplicationPackages = [
        pkgs.gnome-text-editor
        pkgs.loupe
        pkgs.totem
      ];
    };

    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
