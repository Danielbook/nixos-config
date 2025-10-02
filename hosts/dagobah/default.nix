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
  ];

  # Set hostname to our Star Wars theme
  networking.hostName = hostname;

  # Dagobah-specific configuration
  # This swampy planet runs our home automation and monitoring services
  
  # Additional server packages for this specific host
  environment.systemPackages = with pkgs; [
    docker-compose  # For managing our container stacks
    jq             # JSON processing for API work
    python3        # For Home Assistant scripts
  ];

  # Dagobah-specific firewall configuration
  # This swampy planet hosts our home automation and monitoring services
  networking.firewall = {
    allowedTCPPorts = [
      80    # HTTP (Traefik)
      443   # HTTPS (Traefik)
      8123  # Home Assistant
      3000  # Grafana (non-standard port)
      3100  # Loki
      8086  # InfluxDB
      5050  # AppDaemon
      6052  # ESPHome
      8080  # Portainer
      8443  # UniFi HTTPS
      8880  # UniFi HTTP redirect
      3478  # UniFi STUN
    ];
    allowedUDPPorts = [
      3478  # UniFi STUN
      10001 # UniFi device discovery
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}