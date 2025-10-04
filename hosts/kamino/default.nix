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
    inputs.sops-nix.nixosModules.sops
    ./disko.nix
    ./services.nix
  ];

  # Set hostname to our Star Wars theme
  networking.hostName = hostname;

  # Secrets management with sops-nix
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    
    # Define all secrets that will be decrypted at runtime
    secrets = {
      # Global secrets
      "kamino/global/ha-appdaemon-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/global/vw-email-pass" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/global/traefik-dashboard-credentials" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      
      # Traefik secrets
      "kamino/traefik/cf-api-token" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      
      # Home Assistant secrets
      "kamino/homeassistant/google-client-id" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homeassistant/google-client-secret" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homeassistant/influxdb-token" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homeassistant/icloud-app-password" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homeassistant/spotify-client-id" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homeassistant/spotify-client-secret" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homeassistant/home-connect-client-id" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homeassistant/home-connect-client-secret" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homeassistant/xiaomi-vacuum-token" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homeassistant/xiaomi-cloud-password" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      
      # ESPHome secrets
      "kamino/esphome/wifi-ssid" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/esphome/wifi-password" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      
      # UniFi secrets
      "kamino/unifi/password" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      
      # Grafana secrets
      "kamino/grafana/admin-password" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      
      # Homepage secrets (API keys)
      "kamino/homepage/proxmox-andromeda-pass" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/proxmox-n4-pass" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/proxmox-hoth-pass" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/portainer-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/jellyfin-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/jellyseerr-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/sonarr-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/radarr-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/lidarr-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/prowlarr-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/deluge-pass" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/nzbget-pass" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/immich-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/home-assistant-token" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/openweathermap-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      "kamino/homepage/weatherapi-key" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
      
      # CloudFlare DDNS
      "kamino/cloudflare-ddns/api-token" = {
        owner = "root";
        group = "docker";
        mode = "0440";
      };
    };
  };

  # Boot configuration for UEFI systems
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kamino-specific configuration
  # This oceanic planet hosts our home automation and monitoring services
  # Like the advanced cloning facilities, this server manages automated systems
  
  # Additional server packages for this specific host
  environment.systemPackages = with pkgs; [
    docker-compose  # For managing our container stacks
    jq             # JSON processing for API work
    python3        # For Home Assistant scripts
  ];

  # Kamino-specific firewall configuration
  # This oceanic planet hosts our home automation and monitoring services
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