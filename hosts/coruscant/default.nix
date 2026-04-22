{
  hostname,
  nixosModules,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    "${nixosModules}/common"
    "${nixosModules}/desktop/common"
    "${nixosModules}/desktop/hyprland"
    "${nixosModules}/services/tlp"
    "${nixosModules}/services/usb-serial"
    "${nixosModules}/services/audio-lowlatency"
    "${nixosModules}/graphics"
    "${nixosModules}/memory-protection"
  ];

  # Set hostname
  networking.hostName = hostname;

  # Enable aarch64 emulation for cross-compilation
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # NFS client support (for TrueNAS media share over WireGuard)
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;

  # TrueNAS photos dataset, accessed over the home-vpn WireGuard tunnel.
  # Uses automount so VPN/NAS downtime doesn't hang boot or file managers —
  # the mount happens on first access and unmounts after 10 min idle.
  fileSystems."/mnt/photos" = {
    device = "10.10.40.10:/mnt/pool1/media/photos";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
      "_netdev"
      "soft"
      "timeo=100"
      "retrans=2"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
