{
  lib,
  inputs,
  pkgs,
  ...
}: let
  walls = inputs.walls;
  swwwitch = inputs.swwwitch.packages.${pkgs.system}.default;
in {
  options.wallpaper = {
    default = lib.mkOption {
      type = lib.types.path;
      default = ./wallpaper.jpg;
      description = "Path to default wallpaper for initial load";
    };
  };

  config = {
    home.packages = [ swwwitch ];

    # Configure swwwitch to use dharmx/walls collection
    home.sessionVariables = {
      SWWWITCH_WALLPAPERS = "${walls}";
    };
  };
}
