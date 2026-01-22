{ config, pkgs, ... }:

{
  # Minimal Tatooine configuration for initial deployment
  # Services will be added incrementally after verifying base system works

  # Enable Docker (but no services yet)
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;

    daemon.settings = {
      log-driver = "json-file";
      log-opts = {
        max-size = "100m";
        max-file = "3";
      };
    };
  };

  # NVIDIA drivers - commented out for minimal deployment
  # Uncomment after base system is verified
  # hardware.graphics = {
  #   enable = true;
  #   enable32Bit = true;
  # };
  # hardware.nvidia-container-toolkit.enable = true;
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   powerManagement.enable = false;
  #   open = false;
  #   nvidiaSettings = false;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

  # TrueNAS mounts - commented out for minimal deployment
  # Uncomment and configure credentials after base system verification
  # fileSystems."/mnt/truenas/data" = {
  #   device = "//10.10.40.10/data";
  #   fsType = "cifs";
  #   options = [
  #     "vers=3.0"
  #     "credentials=/etc/nixos/truenas-credentials"
  #     "uid=1000"
  #     "gid=1000"
  #     "file_mode=0775"
  #     "dir_mode=0775"
  #     "iocharset=utf8"
  #     "soft"
  #     "x-systemd.automount"
  #     "x-systemd.idle-timeout=300"
  #     "x-systemd.device-timeout=10"
  #     "x-systemd.mount-timeout=10"
  #     "_netdev"
  #   ];
  # };

  # Create basic directory structure
  systemd.tmpfiles.rules = [
    "d /srv 0755 root root -"
    "d /srv/docker 0755 daniel docker -"
  ];

  # Add daniel to docker group for managing containers
  users.users.daniel.extraGroups = [ "docker" ];

  # Minimal packages for initial deployment
  environment.systemPackages = with pkgs; [
    docker-compose
    docker
    htop
  ];
}

# Services to add later:
# - NVIDIA drivers and container toolkit
# - TrueNAS CIFS mounts
# - Docker Compose systemd services
# - Firewall ports for services
