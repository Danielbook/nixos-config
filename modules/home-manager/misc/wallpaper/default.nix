{
  lib,
  inputs,
  ...
}: {
  options.wallpaper = {
    default = lib.mkOption {
      type = lib.types.path;
      default = ./wallpaper.jpg;
      description = "Path to default wallpaper for initial load";
    };
  };

  config = {
    # Stable symlink to walls collection for Noctalia wallpaper management
    home.file.".local/share/wallpapers".source = inputs.walls;
  };
}
