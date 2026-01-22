# Tatooine Migration to NixOS

## Overview
This document outlines the migration of tatooine from Debian 12 (Proxmox VM) to NixOS, transforming it into a declaratively managed media server.

**Current Setup:**
- OS: Debian 12 (Bookworm) in Proxmox VM
- Hardware: Intel i7-8700K (12 cores), NVIDIA GTX 1070, 2GB RAM, 64GB disk
- Services: Jellyfin, Immich, Jellyseerr, n8n, Tailscale, Watchtower, Portainer Agent, Authentik Outpost
- Storage: CIFS mount from TrueNAS (//10.10.40.10/data) for media and photos

**Target State:**
- OS: NixOS 25.05 (declarative, flake-based)
- Same hardware, GPU transcoding enabled
- All services running in Docker containers (managed by systemd)
- Declarative infrastructure matching kamino's pattern

## Migration Strategy

### Phase 1: VM Testing in Proxmox ✅ RECOMMENDED FIRST
Test the NixOS configuration in a fresh Proxmox VM before touching the production system.

**Steps:**
1. **Create test VM in Proxmox:**
   ```bash
   # In Proxmox UI:
   # - Create VM with same specs as production tatooine
   # - Name it "tatooine-nixos-test"
   # - Give it a different IP (e.g., 10.10.40.13)
   # - Boot from NixOS minimal ISO
   ```

2. **Update justfile for test VM:**
   ```bash
   # Temporarily change tatooine_host variable in justfile:
   tatooine_host := "10.10.40.13"  # Test VM IP
   ```

3. **Deploy NixOS to test VM:**
   ```bash
   just deploy-tatooine
   ```

4. **Manually copy docker-compose files from production:**
   ```bash
   # From your workstation:
   rsync -av daniel@10.10.40.11:/srv/docker/ daniel@10.10.40.13:/srv/docker/

   # Don't forget the .env files:
   rsync -av daniel@10.10.40.11:/srv/docker/immich/.env daniel@10.10.40.13:/srv/docker/immich/
   rsync -av daniel@10.10.40.11:/srv/docker/tailscale/.env daniel@10.10.40.13:/srv/docker/tailscale/
   ```

5. **Test services in the VM:**
   ```bash
   ssh root@10.10.40.13 'systemctl status docker-compose-tatooine'
   ssh root@10.10.40.13 'docker ps'

   # Verify GPU is detected:
   ssh root@10.10.40.13 'nvidia-smi'

   # Test Jellyfin GPU transcoding
   # Test Immich photo upload
   # Test n8n workflows
   ```

6. **If everything works:** Proceed to Phase 2
7. **If issues found:** Debug and fix configuration, iterate

### Phase 2: Bare Metal Migration
Once VM testing is successful, migrate the production system.

**Pre-Migration Checklist:**
- [ ] Backup all docker volumes from current tatooine
- [ ] Export Immich database
- [ ] Document all .env file contents (credentials, tokens)
- [ ] Note down Tailscale authkey
- [ ] Test VM is fully functional with all services
- [ ] Inform users of downtime window

**Migration Steps:**

1. **Backup production data:**
   ```bash
   # SSH into current tatooine (Debian)
   ssh daniel@tatooine

   # Backup all docker data
   sudo tar -czf /tmp/tatooine-docker-backup.tar.gz /srv/docker

   # Copy backup off the server
   scp daniel@tatooine:/tmp/tatooine-docker-backup.tar.gz ~/backups/
   ```

2. **Update justfile to production IP:**
   ```bash
   # Restore original IP in justfile:
   tatooine_host := "10.10.40.11"
   ```

3. **Deploy NixOS with nixos-anywhere:**
   ```bash
   # This will WIPE the disk!
   just deploy-tatooine

   # nixos-anywhere will:
   # 1. Kexec into NixOS installer
   # 2. Partition disk with disko
   # 3. Install NixOS
   # 4. Reboot into new system
   ```

4. **Restore docker-compose files:**
   ```bash
   # Restore from backup or copy from test VM
   rsync -av ~/backups/tatooine-docker/ root@tatooine:/srv/docker/

   # Or copy from test VM:
   rsync -av daniel@10.10.40.13:/srv/docker/ root@tatooine:/srv/docker/
   ```

5. **Start services:**
   ```bash
   ssh root@tatooine 'systemctl restart docker-compose-tatooine'
   ssh root@tatooine 'docker ps'
   ```

6. **Verify everything works:**
   ```bash
   # Check Jellyfin: http://10.10.40.11:8096
   # Check Immich: http://10.10.40.11:2283
   # Check n8n: http://10.10.40.11:5678
   # Check GPU: ssh root@tatooine 'nvidia-smi'
   ```

## Debugging nixos-anywhere Issues

Based on your previous kamino experience where the VM didn't boot after deployment:

### Common Issues and Solutions

**Issue 1: System doesn't boot after deployment**
- **Cause:** Ran nixos-anywhere against an already-installed NixOS, disko reformatted the disk and broke bootloader
- **Solution:** Always run nixos-anywhere against:
  - Fresh Debian/Ubuntu system (it will kexec into NixOS installer)
  - NixOS minimal ISO boot
  - Never against an already-configured NixOS system

**Issue 2: Kexec fails**
```bash
# If nixos-anywhere fails during kexec, try manual install:
# 1. Boot from NixOS minimal ISO in Proxmox
# 2. SSH into the ISO environment
# 3. Run deployment manually:
nixos-anywhere --flake .#tatooine root@tatooine-ip
```

**Issue 3: Disk partitioning errors**
```bash
# Check disko configuration is valid:
nix flake check

# View what disko will do:
nix run github:nix-community/disko -- --mode dry-run --flake .#tatooine
```

**Issue 4: NVIDIA drivers not loading**
```bash
# After deployment, check driver status:
ssh root@tatooine 'nvidia-smi'

# If it fails, check kernel logs:
ssh root@tatooine 'journalctl -b | grep -i nvidia'

# Rebuild to apply NVIDIA fixes:
ssh root@tatooine 'nixos-rebuild switch'
```

**Issue 5: Docker services won't start**
```bash
# Check systemd service status:
ssh root@tatooine 'systemctl status docker-compose-tatooine'

# Check if Docker daemon is running:
ssh root@tatooine 'docker info'

# Check if GPU is available to Docker:
ssh root@tatooine 'docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi'
```

### Manual Fallback: Traditional NixOS Install

If nixos-anywhere keeps failing, use traditional installation:

1. **Boot NixOS minimal ISO in Proxmox**

2. **Manual partitioning:**
   ```bash
   # Partition disk (similar to disko.nix):
   parted /dev/sda -- mklabel gpt
   parted /dev/sda -- mkpart ESP fat32 1MB 512MB
   parted /dev/sda -- set 1 esp on
   parted /dev/sda -- mkpart primary linux-swap 512MB 1.5GB
   parted /dev/sda -- mkpart primary ext4 1.5GB 100%

   # Format partitions:
   mkfs.fat -F 32 -n boot /dev/sda1
   mkswap -L swap /dev/sda2
   mkfs.ext4 -L nixos /dev/sda3

   # Mount:
   mount /dev/sda3 /mnt
   mkdir -p /mnt/boot
   mount /dev/sda1 /mnt/boot
   swapon /dev/sda2
   ```

3. **Generate initial config:**
   ```bash
   nixos-generate-config --root /mnt

   # Copy the generated hardware-configuration.nix:
   cat /mnt/etc/nixos/hardware-configuration.nix
   # Paste this into hosts/tatooine/hardware-configuration.nix in your repo
   ```

4. **Install from your flake:**
   ```bash
   # Clone your repo on the installer:
   nix-shell -p git
   git clone https://github.com/yourusername/nixos-config /tmp/nixos-config
   cd /tmp/nixos-config

   # Update hardware-configuration.nix with the generated one

   # Install:
   nixos-install --flake .#tatooine

   # Set root password when prompted
   ```

5. **Reboot and finish setup:**
   ```bash
   reboot

   # After reboot, SSH in and setup TrueNAS credentials:
   just setup-tatooine-credentials
   ```

## Service-Specific Notes

### Jellyfin + NVIDIA GTX 1070
- Hardware transcoding is configured via `virtualisation.docker.enableNvidia = true`
- The GTX 1070 will appear in the container as `/dev/nvidia0`
- Ensure docker-compose.yaml has the NVIDIA runtime configured:
  ```yaml
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
  ```

### Immich
- Requires PostgreSQL with vector extensions (pgvectors)
- Database is in the Immich compose stack
- **Important:** Backup the PostgreSQL database before migration
- .env file contains critical DB credentials

### n8n
- Requires Docker socket access for managing containers
- Volume mounted: `/var/run/docker.sock:/var/run/docker.sock:ro`
- All workflows and credentials are in `/srv/docker/n8n/data`

### Tailscale
- Requires privileged container with NET_ADMIN capability
- Authkey in .env file needs to be valid
- Serves Jellyfin and Jellyseerr on the tailnet

## Post-Migration Tasks

- [ ] Update DNS/DHCP to point tatooine hostname to new IP (if changed)
- [ ] Test all Jellyfin clients (web, apps, Tailscale)
- [ ] Verify Immich photo uploads and timeline
- [ ] Test n8n workflows
- [ ] Monitor GPU usage during transcoding
- [ ] Schedule regular backups with the NixOS backup timer
- [ ] Update CLAUDE.md with tatooine deployment notes
- [ ] Document any issues encountered in this file

## Rollback Plan

If the migration fails catastrophically:

1. **Restore from backup:**
   ```bash
   # Reinstall Debian from Proxmox
   # Restore /srv/docker from backup:
   scp ~/backups/tatooine-docker-backup.tar.gz daniel@tatooine:/tmp/
   ssh daniel@tatooine 'sudo tar -xzf /tmp/tatooine-docker-backup.tar.gz -C /'

   # Start all compose stacks:
   cd /srv/docker/jellyfin && docker-compose up -d
   cd /srv/docker/immich && docker-compose up -d
   # ... etc
   ```

2. **Or:** Keep the test VM running as production temporarily while you debug NixOS

## Future Improvements

Once basic migration is working:

- [ ] Convert Tailscale to native NixOS service (`services.tailscale`)
- [ ] Add sops-nix secrets management for credentials
- [ ] Consider native `services.jellyfin` instead of Docker
- [ ] Add automated backups to TrueNAS
- [ ] Implement monitoring with Prometheus/Grafana
- [ ] Add to kamino's Homepage dashboard

## Resources

- [nixos-anywhere Documentation](https://github.com/nix-community/nixos-anywhere)
- [Disko Examples](https://github.com/nix-community/disko/tree/master/example)
- [NixOS NVIDIA Drivers](https://nixos.wiki/wiki/Nvidia)
- [Docker on NixOS](https://nixos.wiki/wiki/Docker)
