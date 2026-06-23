{
  config,
  lib,
  pkgs,
  ...
}:
let
  qtCtAppearanceConfig = lib.generators.toINI { } {
    Appearance = {
      icon_theme = config.gtk.iconTheme.name;
    };
  };
in
{
  home.packages = [
    pkgs.libsForQt5.qtstyleplugin-kvantum
    pkgs.libsForQt5.qt5ct
  ];

  # Colors managed by Noctalia
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  xdg.configFile = {
    qt5ct = {
      target = "qt5ct/qt5ct.conf";
      text = qtCtAppearanceConfig;
    };

    qt6ct = {
      target = "qt6ct/qt6ct.conf";
      text = qtCtAppearanceConfig;
    };
  };
}
