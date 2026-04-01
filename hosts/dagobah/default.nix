{
  hostname,
  darwinModules,
  ...
}: {
  imports = [
    "${darwinModules}/common"
  ];

  networking.hostName = hostname;
}
