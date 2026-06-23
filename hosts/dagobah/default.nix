{
  hostname,
  darwinModules,
  ...
}:
{
  imports = [
    "${darwinModules}/common"
  ];

  networking.hostName = hostname;

  # Apple Silicon MacBook Pro
  nixpkgs.hostPlatform = "aarch64-darwin";
}
