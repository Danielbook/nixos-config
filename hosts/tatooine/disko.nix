# Tatooine disk configuration using disko
# This will partition and format the disk during nixos-anywhere deployment
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            # EFI boot partition
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["defaults"];
              };
            };
            # Swap partition (1GB)
            swap = {
              size = "1G";
              content = {
                type = "swap";
                randomEncryption = false;
              };
            };
            # Root partition (rest of disk)
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = ["defaults"];
              };
            };
          };
        };
      };
    };
  };
}
