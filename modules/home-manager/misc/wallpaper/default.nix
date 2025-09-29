{lib, ...}: {
  options.wallpaper = lib.mkOption {
    type = lib.types.path;
    default = ./wallpaper2.gif;
    readOnly = true;
    description = "Path to default wallpaper";
  };
}
