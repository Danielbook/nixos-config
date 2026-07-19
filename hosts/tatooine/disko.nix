# Declarative partitioning for tatooine's bare-metal NVMe (see ADR-0003).
# disko wipes this disk on nixos-anywhere install — tatooine only, blank disk only.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1"; # confirmed via lsblk on the physical Proxmox host, 476.9G
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
