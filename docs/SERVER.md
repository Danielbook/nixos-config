# 🖥️ Server Deployment & Infrastructure

This configuration supports both desktop workstations and production-ready headless servers with automated deployment.

## 🌟 Available Server Configurations

- **🌊 Kamino**: Home automation and monitoring server (Home Assistant, Grafana, Traefik)
- **🏜️ Tatooine**: Coming soon...
- **❄️ Hoth**: Coming soon...

---

## 🌊 Kamino Server Infrastructure

**Kamino** is our Star Wars-themed home automation and monitoring server, hosting a comprehensive Docker-based infrastructure for smart home management.

### 🏗️ Architecture Overview

```
🌊 Kamino (10.10.40.20)
├── 🔒 Traefik (Reverse Proxy & SSL)
├── 🏠 Home Assistant Stack
│   ├── Home Assistant Core
│   ├── ESPHome (IoT device management)
│   └── AppDaemon (Automation engine)
├── 📊 Grafana Monitoring Stack
│   ├── Grafana (Visualization)
│   ├── Loki (Log aggregation)
│   ├── Prometheus (Metrics)
│   └── InfluxDB (Time series data)
├── 🌐 Network Services
│   ├── UniFi Controller
│   ├── CloudFlare DDNS
│   └── Homepage Dashboard
├── 🖨️ OctoPrint (3D Printer)
└── 📡 Promtail Remote (Log shipping)
```

### 🚀 Services Portfolio

| Service | Purpose | Port | URL |
|---------|---------|------|-----|
| 🔒 **Traefik** | Reverse proxy, SSL termination | 80/443 | `traefik.local.bookorjeman.com` |
| 🏠 **Home Assistant** | Smart home automation hub | 8123 | `homeassistant.local.bookorjeman.com` |
| 📊 **Grafana** | Metrics visualization dashboard | 3000 | `grafana.local.bookorjeman.com` |
| 📈 **InfluxDB** | Time series database | 8086 | Internal |
| 📋 **Loki** | Log aggregation system | 3100 | Internal |
| 🌐 **UniFi Controller** | Network device management | 8443 | `unifi.local.bookorjeman.com` |
| 🖨️ **OctoPrint** | 3D printer management | 5000 | `octoprint.local.bookorjeman.com` |
| 🏡 **Homepage** | Service dashboard | 3300 | `homepage.local.bookorjeman.com` |
| 🔧 **ESPHome** | IoT device configuration | 6052 | `esphome.local.bookorjeman.com` |
| ⚡ **AppDaemon** | Advanced automations | 5050 | Internal |

### 🔐 Security Features

- **🛡️ Zero-Trust Networking**: All traffic through Traefik with SSL termination
- **🔑 Encrypted Secrets**: All credentials managed via sops-nix + Age encryption
- **🚫 No Hardcoded Passwords**: All secrets injected at runtime
- **🔥 Host Firewall**: Restrictive iptables rules, only required ports open
- **📱 Multi-Factor Auth**: Integrated with external OAuth providers

### 📊 Monitoring & Observability

- **📈 Metrics**: Prometheus scraping all service endpoints
- **📋 Logs**: Centralized logging via Loki with retention policies
- **📊 Dashboards**: Pre-configured Grafana dashboards for all services
- **🔔 Alerting**: Smart home and infrastructure alerts via Home Assistant
- **📱 Mobile**: Home Assistant companion app with push notifications

### 🌐 DNS & Networking

- **🏠 Local DNS**: `.local.bookorjeman.com` domain for internal services
- **🔄 Dynamic DNS**: Automated CloudFlare DNS updates
- **🌍 External Access**: Secure remote access via Traefik + CloudFlare
- **📡 IoT Network**: Segregated VLAN for smart home devices

---

## 🚀 Remote Deployment with nixos-anywhere

Deploy NixOS servers remotely with full automation.

### 1. 🖥️ Prepare Target Machine

Create VM or physical server with NixOS minimal ISO:

```bash
# On the target machine console
sudo systemctl start sshd
passwd nixos  # Set temporary password for nixos user
ip addr show  # Note the IP address for deployment
```

### 2. 🚢 Deploy Kamino Server

**One-command deployment** with automated secrets:

```bash
# Deploy complete Kamino infrastructure
just deploy-kamino
```

This command will:
- ✅ Check connectivity to target server
- 🚀 Deploy NixOS configuration via nixos-anywhere
- 🔑 Set up Age encryption keys for secrets
- 🐳 Start all Docker services automatically
- 📊 Configure monitoring and logging

### 3. 🔧 Manual Secret Setup

If Bitwarden CLI is unavailable:

```bash
# Set up secrets manually if Bitwarden CLI fails
just setup-kamino-secrets

# Check Bitwarden CLI status and configuration
just check-bw
```

### 4. ✅ Verify Deployment

```bash
# Check running services
ssh root@10.10.40.20 'docker ps'

# Verify Home Assistant
curl -k https://homeassistant.local.bookorjeman.com

# Check service logs
ssh root@10.10.40.20 'docker-compose -f /srv/homeassistant-stack/docker-compose.yaml logs'
```

## 📦 Data Migration (Optional)

When replacing existing servers, migrate Docker volumes:

```bash
# Stop services on old server (Jupiter)
ssh jupiter "cd /srv && for dir in */; do cd \$dir && docker-compose down && cd ..; done"

# Create backup archive
ssh jupiter "tar czf /tmp/srv-backup.tar.gz /srv/"

# Transfer to new server
scp jupiter:/tmp/srv-backup.tar.gz .
scp srv-backup.tar.gz kamino:/tmp/

# Restore on Kamino (before first boot)
ssh kamino "cd / && sudo tar xzf /tmp/srv-backup.tar.gz"
```

## ⚙️ Server Features

- **🔒 Secure by Default**: SSH hardening, minimal attack surface
- **🐳 Container Orchestration**: Auto-discovery and management of Docker services
- **🔥 Smart Firewalls**: Host-specific port configurations
- **📊 Built-in Monitoring**: System metrics and log aggregation
- **🎯 Minimal Footprint**: Server-optimized package selection
- **🔄 Self-Healing**: Systemd service recovery and health checks

## 🛠️ Advanced Deployment Options

```bash
# Deploy with custom target IP
nixos-anywhere --flake .#kamino nixos@192.168.1.100

# Deploy with disk encryption (enterprise)
nixos-anywhere --flake .#kamino-encrypted nixos@10.10.40.20

# Dry-run deployment (test configuration)
nixos-anywhere --flake .#kamino --dry-run nixos@10.10.40.20
```

## 🚀 Deployment Commands

This repository uses **Just** (modern alternative to Make) for all deployment and management tasks.

### Server Deployment Commands

```bash
# Deploy Kamino home automation server
just deploy-kamino          # Full deployment with secrets setup

# Secrets management
just setup-kamino-secrets   # Set up Age encryption keys only
just check-bw               # Check Bitwarden CLI status

# Future server deployments
just deploy-tatooine        # Coming soon
just deploy-hoth           # Coming soon
```

### Management Commands

```bash
# Show all available commands
just --list

# Show detailed help with examples
just help

# Update flake inputs
just flake-update

# Validate configuration
just flake-check

# Garbage collection
just nix-gc
```

## 🔍 Troubleshooting

### Deployment Issues

```bash
# Test connectivity
ping 10.10.40.20
ssh nixos@10.10.40.20 "echo 'Connected successfully'"

# Check deployment logs
just deploy-kamino --show-trace

# Verify configuration syntax
just flake-check
```

### Service Issues

```bash
# Check service status
ssh root@kamino "systemctl status docker"
ssh root@kamino "docker ps -a"

# View logs
ssh root@kamino "journalctl -u docker -n 100"
ssh root@kamino "docker-compose -f /srv/homeassistant-stack/docker-compose.yaml logs"

# Restart services
ssh root@kamino "systemctl restart docker"
ssh root@kamino "docker-compose -f /srv/homeassistant-stack/docker-compose.yaml restart"
```

### Network Issues

```bash
# Check firewall rules
ssh root@kamino "iptables -L -n"

# Test service connectivity
curl -k https://homeassistant.local.bookorjeman.com
curl -k https://grafana.local.bookorjeman.com

# Check DNS resolution
dig homeassistant.local.bookorjeman.com
```

## 📚 Additional Resources

- [nixos-anywhere Documentation](https://github.com/nix-community/nixos-anywhere)
- [Secrets Management Guide](./SECRETS.md)
- [Home Assistant Documentation](https://www.home-assistant.io/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)

## 🎯 Quick Reference

```bash
# Full deployment workflow
just deploy-kamino

# Check deployment status
ssh root@kamino "systemctl status"

# View all services
ssh root@kamino "docker ps"

# Access web interfaces
open https://homepage.local.bookorjeman.com

# Update server configuration
just deploy-kamino

# Backup server data
ssh root@kamino "tar czf /tmp/backup.tar.gz /srv"
```
