{
  hostname,
  nixosModules,
  ...
}: {
  ##### Base hardware profile (pulls in good defaults)
  # If you use flakes, import nixos-hardware:
  # inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";
  # then:
  imports = [
    # Pick the ones that fit your setup
    # inputs.nixos-hardware.nixosModules.common-cpu-intel
    # inputs.nixos-hardware.nixosModules.common-pc-laptop
    # inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
    "${nixosModules}/common"
    "${nixosModules}/desktop/hyprland"
    #"${nixosModules}/desktop/kde"
    "${nixosModules}/services/tlp"
    "${nixosModules}/nvidia"
    "${nixosModules}/memory-protection"
  ];

  # Set hostname
  networking.hostName = hostname;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
