# Declarative partitioning for naboo's 128G NVMe (plan 003).
# disko wipes this disk on nixos-anywhere install — naboo only, blank disk only.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1"; # confirm with `lsblk` on the box before install
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
