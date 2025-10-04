#!/bin/bash
# Promtail Remote Deployment Script
# Usage: curl -sSL http://jupiter-ip/deploy-promtail.sh | bash -s -- <hostname> <loki-ip>
# Or: Run this script directly on each machine with hostname as argument

set -e

# Configuration
LOKI_URL="${2:-http://10.10.40.20:3100}"
HOSTNAME="${1}"
INSTALL_DIR="/srv/promtail"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z "$HOSTNAME" ]; then
    echo -e "${RED}Error: Hostname required${NC}"
    echo "Usage: $0 <hostname> [loki-url]"
    echo "Example: $0 servarr http://10.10.40.20:3100"
    echo ""
    echo "Valid hostnames: servarr, tatooine"
    exit 1
fi

if [ "$HOSTNAME" != "servarr" ] && [ "$HOSTNAME" != "tatooine" ]; then
    echo -e "${YELLOW}Warning: Expected 'servarr' or 'tatooine', got '$HOSTNAME'${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Promtail Remote Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Hostname: $HOSTNAME"
echo "Loki URL: $LOKI_URL"
echo "Install Directory: $INSTALL_DIR"
echo ""

# Create installation directory
echo -e "${YELLOW}[1/5] Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Create Promtail configuration
echo -e "${YELLOW}[2/5] Creating Promtail configuration...${NC}"
cat > promtail-config.yaml << 'CONFIGEOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: LOKI_URL_PLACEHOLDER/loki/api/v1/push

scrape_configs:

# System logs
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: system
      host: HOSTNAME_PLACEHOLDER
      __path__: /var/log/*.log

# Auth logs (SSH, sudo)
- job_name: auth
  static_configs:
  - targets:
      - localhost
    labels:
      job: auth
      host: HOSTNAME_PLACEHOLDER
      __path__: /var/log/auth.log

# Docker container logs
- job_name: docker
  pipeline_stages:
    - docker: {}
    - json:
        expressions:
          stream: stream
          time: time
    - labels:
        stream:
    - timestamp:
        source: time
        format: RFC3339Nano
  static_configs:
    - targets:
        - localhost
      labels:
        job: docker
        host: HOSTNAME_PLACEHOLDER
        __path__: /var/lib/docker/containers/*/*-json.log
CONFIGEOF

# Replace placeholders
sed -i "s|LOKI_URL_PLACEHOLDER|${LOKI_URL}|g" promtail-config.yaml
sed -i "s|HOSTNAME_PLACEHOLDER|${HOSTNAME}|g" promtail-config.yaml

echo -e "${GREEN}✓ Configuration created${NC}"

# Create docker-compose file
echo -e "${YELLOW}[3/5] Creating docker-compose file...${NC}"
cat > docker-compose.yaml << 'COMPOSEEOF'
---
services:
  promtail:
    container_name: promtail
    image: grafana/promtail:2.9.4
    volumes:
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./promtail-config.yaml:/etc/promtail/promtail-config.yaml:ro
    restart: unless-stopped
    command: -config.file=/etc/promtail/promtail-config.yaml
    network_mode: bridge
COMPOSEEOF

echo -e "${GREEN}✓ Docker compose file created${NC}"

# Check if Docker is available
echo -e "${YELLOW}[4/5] Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Docker daemon${NC}"
    echo "Make sure Docker is running and you have permissions"
    exit 1
fi

echo -e "${GREEN}✓ Docker is available${NC}"

# Deploy Promtail
echo -e "${YELLOW}[5/5] Deploying Promtail...${NC}"

# Stop existing container if running
if docker ps -a --format '{{.Names}}' | grep -q '^promtail$'; then
    echo "Stopping existing Promtail container..."
    docker stop promtail || true
    docker rm promtail || true
fi

# Start Promtail
docker compose up -d

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Promtail is now running and sending logs to:"
echo "  → $LOKI_URL"
echo ""
echo "Check status:"
echo "  docker ps | grep promtail"
echo "  docker logs promtail"
echo ""
echo "View logs in Grafana:"
echo "  https://grafana.local.bookorjeman.com"
echo "  Query: {host=\"$HOSTNAME\"}"
echo ""

# Show recent logs
echo -e "${YELLOW}Recent Promtail logs:${NC}"
sleep 3
docker logs promtail --tail 10 2>&1 || true