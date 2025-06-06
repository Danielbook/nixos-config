{
  inputs,
  hostname,
  nixosModules,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    "${nixosModules}/common"
    "${nixosModules}/desktop/hyprland"
    "${nixosModules}/services/tlp"
    "${nixosModules}/nvidia"
  ];

  # Set hostname
  networking.hostName = hostname;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
