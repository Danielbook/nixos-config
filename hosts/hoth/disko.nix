# Declarative partitioning for hoth's disk (HP EliteDesk 800 G2 Mini, SATA SSD,
# confirmed /dev/sda via lsblk on the Proxmox host itself — 238.5G Samsung
# MZ7TY256HDHP, not NVMe like naboo/endor/tatooine. Box previously ran Proxmox
# VE with a single VM ("jupiter", VMID 101) consuming nearly all its resources
# (104G/16G of 238.5G/16G) — same pattern as tatooine's D1 install: VM stopped,
# then nixos-anywhere kexecs from the live Proxmox host and replaces it with
# bare-metal NixOS. root is 100%. disko WIPES this disk on nixos-anywhere
# install — hoth only, blank disk only.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
