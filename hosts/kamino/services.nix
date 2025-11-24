{ config, pkgs, ... }:

{
  # Docker service deployment configuration for Kamino
  # This module sets up systemd services to manage Docker Compose stacks

  systemd.services = {
    # Global Docker Compose service that starts all services
    docker-compose-kamino = {
      description = "Start all Kamino Docker Compose services";
      after = [ "docker.service" "network.target" ];
      wants = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      
      script = ''
        set -e
        
        # Wait for Docker to be ready
        while ! ${pkgs.docker}/bin/docker info >/dev/null 2>&1; do
          echo "Waiting for Docker daemon..."
          sleep 2
        done
        
        echo "Docker is ready, starting Kamino services..."
        
        # Define service directories in deployment order
        SERVICES=(
          "traefik"
          "grafana-stack"
          "homeassistant-stack"
          "unifi"
          "homepage"
          "cloudflare-ddns"
          "octoprint"
          "portainer"
          "mealie"
        )
        
        # Start each service
        for service in "''${SERVICES[@]}"; do
          service_dir="/srv/kamino/$service"
          if [ -d "$service_dir" ] && [ -f "$service_dir/docker-compose.yaml" ]; then
            echo "Starting $service..."
            cd "$service_dir"
            ${pkgs.docker-compose}/bin/docker-compose up -d || {
              echo "Failed to start $service, continuing..."
            }
          else
            echo "Service directory $service_dir not found or missing docker-compose.yaml"
          fi
        done
        
        echo "All Kamino services startup complete"
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Group = "root";
      };
      
      # Restart policy
      restartIfChanged = true;
    };

    # Individual service management (optional, for granular control)
    docker-compose-traefik = {
      description = "Traefik reverse proxy";
      after = [ "docker.service" "network.target" ];
      wants = [ "docker.service" ];
      
      script = ''
        cd /srv/kamino/traefik
        ${pkgs.docker-compose}/bin/docker-compose up -d
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Group = "root";
      };
    };

    docker-compose-homeassistant-stack = {
      description = "Home Assistant and related services";
      after = [ "docker.service" "network.target" "docker-compose-traefik.service" ];
      wants = [ "docker.service" ];
      
      script = ''
        cd /srv/kamino/homeassistant-stack
        ${pkgs.docker-compose}/bin/docker-compose up -d
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Group = "root";
      };
    };

    docker-compose-grafana-stack = {
      description = "Grafana monitoring stack";
      after = [ "docker.service" "network.target" "docker-compose-traefik.service" ];
      wants = [ "docker.service" ];
      
      script = ''
        cd /srv/kamino/grafana-stack
        ${pkgs.docker-compose}/bin/docker-compose up -d
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Group = "root";
      };
    };
  };

  # Filesystem mounts and directory setup
  systemd.tmpfiles.rules = [
    # Create service directories with proper permissions
    "d /srv 0755 root root -"
    "d /srv/kamino 0755 root root -"

    # Create data directories for persistent storage
    "d /srv/kamino-data 0755 root root -"
    "d /srv/kamino-data/homeassistant 0755 root root -"
    "d /srv/kamino-data/grafana 0755 root root -"
    "d /srv/kamino-data/influxdb 0755 root root -"
    "d /srv/kamino-data/prometheus 0755 root root -"
    "d /srv/kamino-data/loki 0755 root root -"
    "d /srv/kamino-data/unifi 0755 root root -"
    "d /srv/kamino-data/traefik 0755 root root -"
    "d /srv/kamino-data/octoprint 0755 root root -"
    "d /srv/kamino-data/portainer 0755 root root -"
    "d /srv/kamino-data/mealie 0755 root root -"
    "d /srv/kamino-data/homepage 0755 root root -"

    # Create secrets directory with restricted permissions
    "d /srv/kamino-secrets 0700 root root -"

    # Create runtime environment files for Docker services
    "d /srv/kamino-runtime 0755 root root -"
    "d /srv/kamino-runtime/env 0755 root root -"
  ];

  # Deploy docker-compose files from repository to /srv/kamino
  system.activationScripts.deployDockerServices = ''
    echo "Deploying Kamino Docker services..."

    # Source directory in the Nix store (this gets copied during deployment)
    DOCKER_SERVICES="${../../files/docker-services/kamino}"

    # Copy docker-compose files and configs to /srv/kamino
    if [ -d "$DOCKER_SERVICES" ]; then
      ${pkgs.rsync}/bin/rsync -av --delete \
        --exclude '.git' \
        --exclude '*.md' \
        --exclude 'promtail-remote' \
        "$DOCKER_SERVICES/" /srv/kamino/

      echo "Docker services deployed to /srv/kamino"
    else
      echo "Warning: Docker services directory not found in Nix store"
    fi

    # Create secret files from sops-nix for services that need them
    echo "Creating secret files from sops-nix..."

    # Traefik CloudFlare API token (traefik expects this as a file)
    mkdir -p /srv/kamino/traefik
    cat ${config.sops.secrets."kamino/traefik/cf-api-token".path} > /srv/kamino/traefik/cf_api_token.txt
    chmod 600 /srv/kamino/traefik/cf_api_token.txt

    # Create main .env file with common variables and secrets
    cat > /srv/kamino/.env <<EOF
DOMAIN=local.bookorjeman.com
SERVER_IP=10.10.40.20
TRAEFIK_DASHBOARD_CREDENTIALS=$(cat ${config.sops.secrets."kamino/global/traefik-dashboard-credentials".path})
HA_APPDAEMON_KEY=$(cat ${config.sops.secrets."kamino/global/ha-appdaemon-key".path})
VW_EMAIL_PASS=$(cat ${config.sops.secrets."kamino/global/vw-email-pass".path})
EOF

    chmod 600 /srv/kamino/.env

    echo "Secrets deployed successfully"
  '';

  # Environment setup
  environment.systemPackages = with pkgs; [
    docker-compose
    docker
  ];

  # Docker configuration
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    
    # Configure Docker daemon
    daemon.settings = {
      log-driver = "json-file";
      log-opts = {
        max-size = "100m";
        max-file = "3";
      };
    };
  };

  # Network configuration for Docker services
  networking.firewall.allowedTCPPorts = [
    # Traefik
    80    # HTTP
    443   # HTTPS
    8080  # Traefik dashboard
    
    # Home Assistant
    8123  # Home Assistant web interface
    
    # ESPHome
    6052  # ESPHome dashboard
    
    # Grafana stack
    3000  # Grafana
    3050  # Grafana (custom port)
    3100  # Loki
    9090  # Prometheus
    8086  # InfluxDB
    
    # UniFi Controller
    8443  # UniFi web interface
    8080  # UniFi device communication
    8843  # UniFi guest portal (HTTPS)
    8880  # UniFi guest portal (HTTP)
    6789  # UniFi mobile speed test
    
    # Homepage dashboard
    3000  # Homepage (if running on different port than Grafana)
    
    # OctoPrint
    5000  # OctoPrint web interface
    
    # Portainer
    9443  # Portainer HTTPS
    9000  # Portainer HTTP
  ];

  networking.firewall.allowedUDPPorts = [
    # UniFi Controller
    3478  # UniFi STUN
    10001 # UniFi device discovery
    1900  # UniFi "Make controller discoverable on L2 network" option
  ];

  # Backup configuration for important data
  # Note: This would typically integrate with your backup solution
  systemd.services.kamino-backup = {
    description = "Backup Kamino service data";
    
    script = ''
      # Create backup directory with timestamp
      BACKUP_DIR="/srv/kamino-backups/$(date +%Y%m%d_%H%M%S)"
      mkdir -p "$BACKUP_DIR"
      
      # Backup important data directories
      echo "Backing up Kamino service data..."
      
      # Stop services before backup (optional, for consistency)
      # systemctl stop docker-compose-kamino.service
      
      # Copy data directories
      if [ -d "/srv/kamino-data" ]; then
        cp -r /srv/kamino-data "$BACKUP_DIR/"
      fi
      
      # Copy secrets (encrypted backups recommended)
      if [ -d "/srv/kamino-secrets" ]; then
        cp -r /srv/kamino-secrets "$BACKUP_DIR/"
      fi
      
      # Restart services
      # systemctl start docker-compose-kamino.service
      
      echo "Backup completed: $BACKUP_DIR"
      
      # Clean up old backups (keep last 7 days)
      find /srv/kamino-backups -type d -name "2*" -mtime +7 -exec rm -rf {} + 2>/dev/null || true
    '';
    
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
    };
  };

  # Schedule daily backups
  systemd.timers.kamino-backup = {
    description = "Daily backup of Kamino services";
    wantedBy = [ "timers.target" ];
    
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}