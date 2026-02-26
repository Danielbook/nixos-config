{
  hostname,
  nixosModules,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    "${nixosModules}/server/headless"
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./services.nix
  ];

  # Set hostname to our Star Wars theme
  networking.hostName = hostname;

  # Boot configuration for UEFI systems
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Tatooine-specific configuration
  # Desert planet hosting our media services
  # Like the twin suns, this server serves content to multiple clients

  # Additional server packages for this specific host
  environment.systemPackages = with pkgs; [
    docker-compose  # For managing our container stacks
    jq              # JSON processing for API work
    nvtop           # NVIDIA GPU monitoring
    htop            # System monitoring
  ];

  # Tatooine-specific firewall configuration
  # Media server with Jellyfin, Immich, Seerr, n8n
  networking.firewall = {
    allowedTCPPorts = [
      # Jellyfin
      8096  # Jellyfin web interface

      # Immich
      2283  # Immich web interface

      # Seerr
      5055  # Seerr web interface

      # n8n
      5678  # n8n automation

      # Portainer Agent
      9001  # Container management
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
