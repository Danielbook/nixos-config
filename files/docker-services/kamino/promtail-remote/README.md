# Promtail Remote Deployment

This directory contains Promtail configurations for deploying log collectors on remote machines that ship logs to the central Loki instance on Jupiter (10.10.40.20:3100).

## Architecture

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Servarr   │      │  Tatooine   │      │   Jupiter   │
│ 10.10.40.11 │      │ 10.10.40.12 │      │ 10.10.40.20 │
│             │      │             │      │             │
│  Promtail   │─────▶│  Promtail   │─────▶│    Loki     │
│             │      │             │      │   :3100     │
└─────────────┘      └─────────────┘      └─────────────┘
                                                  │
                                                  ▼
                                            ┌─────────────┐
                                            │   Grafana   │
                                            │   :3050     │
                                            └─────────────┘
```

## What Gets Collected

Each Promtail instance collects:
- **System logs** - `/var/log/*.log` (syslog, kern.log, etc.)
- **Auth logs** - `/var/log/auth.log` (SSH, sudo attempts)
- **Docker container logs** - All container stdout/stderr

Each log entry is labeled with:
- `job` - Type of log (system/auth/docker)
- `host` - Machine name (servarr/tatooine/jupiter)
- `stream` - stdout or stderr (for Docker logs)

## Deployment Instructions

### ⚡ Quick Deployment (Use this method!)

Since SSH requires public keys, use direct console/terminal access on each machine:

**For Servarr (10.10.40.11):**
```bash
# Log into Servarr console/terminal directly and run:
cd /tmp
curl -O http://10.10.40.20:8000/promtail/deploy-promtail.sh
chmod +x deploy-promtail.sh
./deploy-promtail.sh servarr
```

**For Tatooine (10.10.40.12):**
```bash
# Log into Tatooine console/terminal directly and run:
cd /tmp
curl -O http://10.10.40.20:8000/promtail/deploy-promtail.sh
chmod +x deploy-promtail.sh
./deploy-promtail.sh tatooine
```

**Note:** The script assumes Jupiter hosts the files at `http://10.10.40.20:8000/promtail/`.
If you don't have a web server running, see Manual Deployment below.

### 📝 Manual Deployment (Copy-Paste Method)

If you can't download the script, just copy and paste directly on each machine:

**For Servarr:**
1. Open terminal on Servarr
2. Run: `mkdir -p /srv/promtail && cd /srv/promtail`
3. Create config: `nano promtail-config.yaml`
4. Paste contents from [promtail-config-servarr.yaml](promtail-config-servarr.yaml)
5. Create compose: `nano docker-compose.yaml`
6. Paste contents from [docker-compose-servarr.yaml](docker-compose-servarr.yaml)
7. Start: `docker compose up -d`

**For Tatooine:**
1. Open terminal on Tatooine
2. Run: `mkdir -p /srv/promtail && cd /srv/promtail`
3. Create config: `nano promtail-config.yaml`
4. Paste contents from [promtail-config-tatooine.yaml](promtail-config-tatooine.yaml)
5. Create compose: `nano docker-compose.yaml`
6. Paste contents from [docker-compose-tatooine.yaml](docker-compose-tatooine.yaml)
7. Start: `docker compose up -d`

## Verification

After deployment, check logs are arriving in Grafana:

1. Open Grafana: https://grafana.local.bookorjeman.com
2. Go to **Explore** tab
3. Select **Loki** as data source
4. Run queries:

```logql
# All logs from Servarr
{host="servarr"}

# All Docker logs from Tatooine
{host="tatooine", job="docker"}

# Failed SSH attempts across all machines
{job="auth"} |= "Failed password"

# All container logs with errors
{job="docker"} |= "error"
```

## Useful LogQL Queries

### Security Monitoring
```logql
# Failed SSH attempts
{job="auth"} |= "Failed password"

# Sudo commands
{job="auth"} |= "sudo"

# Root logins
{job="auth"} |= "root"
```

### Docker Monitoring
```logql
# Container errors by host
sum(rate({job="docker"} |= "error" [5m])) by (host)

# Specific container logs (extract container name from path)
{job="docker"} | json | line_format "{{.log}}"

# Container restarts
{job="docker"} |= "Container" |= "started"
```

### System Health
```logql
# Out of memory events
{job="system"} |= "Out of memory"

# Disk errors
{job="system"} |= "I/O error"

# Kernel panics
{job="system"} |= "kernel panic"
```

## Troubleshooting

### Logs not appearing in Loki

1. Check Promtail is running:
```bash
docker ps | grep promtail
docker logs promtail
```

2. Check network connectivity to Loki:
```bash
docker exec promtail wget -O- http://10.10.40.20:3100/ready
```

3. Check Promtail metrics:
```bash
curl http://localhost:9080/metrics
```

### Permission issues

If Promtail can't read Docker logs:
```bash
# Check Docker socket permissions
ls -la /var/run/docker.sock

# Add to docker group if needed
usermod -aG docker $(whoami)
```

## Log Retention

Current Loki retention is configured in `/srv/grafana-stack/loki/loki-config.yaml`. Default is usually 30 days.

To check current retention:
```bash
docker exec loki cat /etc/loki/loki-config.yaml | grep retention
```

## Resource Usage

Each Promtail instance uses approximately:
- **CPU**: ~0.5-1% idle, 2-5% under load
- **Memory**: ~50-100MB
- **Disk**: Minimal (positions file only)
- **Network**: ~1-10KB/s depending on log volume