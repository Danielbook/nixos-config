# Declarative partitioning for endor's NVMe (mirrors naboo). root is 100%, so
# capacity is fine on either the 128G/256G unknown — but CONFIRM the device is
# /dev/nvme0n1 with `lsblk` on the box before install. disko WIPES this disk on
# nixos-anywhere install — endor only, blank disk only.
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
