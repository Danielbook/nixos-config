# PLACEHOLDER hardware config — lets the flake evaluate before hoth exists.
# On first install, REGENERATE this on the box (`nixos-generate-config`) or drive
# partitioning with disko via nixos-anywhere. The bootloader (systemd-boot) is set
# by modules/nixos/common, so it is intentionally omitted here.
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ]; # HP EliteDesk 800 G2 Mini, i7-6700T (Intel)

  # Filesystems + swap are owned by ./disko.nix (declarative partitioning).
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
}
