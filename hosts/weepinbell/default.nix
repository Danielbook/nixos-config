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
    ./hardware-configuration.nix
    "${nixosModules}/common"
    "${nixosModules}/desktop/hyprland"
    "${nixosModules}/services/tlp"
    "${nixosModules}/services/usb-serial"
    "${nixosModules}/services/audio-lowlatency"
    "${nixosModules}/nvidia"
    "${nixosModules}/memory-protection"
  ];

  # Set hostname
  networking.hostName = hostname;

  # Enable aarch64 emulation for cross-compilation
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
