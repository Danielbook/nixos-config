# Headless server home — CLI tooling only (the shared `common` layer). No desktop
# modules, no home secrets.
{ nhModules, ... }:
{
  imports = [
    "${nhModules}/common"
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "25.05";
}
