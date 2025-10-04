# Promtail Quick Deployment Guide

## Current Status
✅ **Jupiter (10.10.40.20)** - Promtail already running, collecting logs from this machine

## To Deploy on Remote Machines

Since SSH requires keys, the easiest method is to **directly access each machine's console/terminal** and paste commands.

---

## Servarr (10.10.40.11)

**Option A - If you have terminal access:**

Open a terminal on Servarr and paste these commands:

```bash
mkdir -p /srv/promtail && cd /srv/promtail

# Create docker-compose.yaml
cat > docker-compose.yaml << 'EOF'
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
EOF

# Create promtail-config.yaml
cat > promtail-config.yaml << 'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://10.10.40.20:3100/loki/api/v1/push

scrape_configs:

- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: system
      host: servarr
      __path__: /var/log/*.log

- job_name: auth
  static_configs:
  - targets:
      - localhost
    labels:
      job: auth
      host: servarr
      __path__: /var/log/auth.log

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
        host: servarr
        __path__: /var/lib/docker/containers/*/*-json.log
EOF

# Start Promtail
docker compose up -d

# Check logs
docker logs promtail
```

---

## Tatooine (10.10.40.12)

**Option A - If you have terminal access:**

Open a terminal on Tatooine and paste these commands:

```bash
mkdir -p /srv/promtail && cd /srv/promtail

# Create docker-compose.yaml
cat > docker-compose.yaml << 'EOF'
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
EOF

# Create promtail-config.yaml
cat > promtail-config.yaml << 'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://10.10.40.20:3100/loki/api/v1/push

scrape_configs:

- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: system
      host: tatooine
      __path__: /var/log/*.log

- job_name: auth
  static_configs:
  - targets:
      - localhost
    labels:
      job: auth
      host: tatooine
      __path__: /var/log/auth.log

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
        host: tatooine
        __path__: /var/lib/docker/containers/*/*-json.log
EOF

# Start Promtail
docker compose up -d

# Check logs
docker logs promtail
```

---

## Verification

After deploying on both machines, view logs in Grafana:

1. Open: **https://grafana.local.bookorjeman.com**
2. Click **Explore** (compass icon)
3. Select **Loki** data source
4. Try these queries:

```logql
# All logs from Servarr
{host="servarr"}

# All logs from Tatooine
{host="tatooine"}

# All Docker logs from all hosts
{job="docker"}

# Failed SSH attempts across all machines
{job="auth"} |= "Failed password"

# Container errors across all hosts
{job="docker"} |= "error"
```

---

## What Gets Logged

From each machine:
- 📋 **System logs** - syslog, kernel logs, daemon logs
- 🔐 **Auth logs** - SSH attempts, sudo usage
- 🐳 **Docker logs** - All container stdout/stderr

All logs are labeled with:
- `host` - jupiter, servarr, or tatooine
- `job` - system, auth, or docker
- `stream` - stdout or stderr (for Docker logs)

---

## Troubleshooting

**Promtail not starting?**
```bash
docker logs promtail
docker ps -a | grep promtail
```

**Logs not appearing in Grafana?**
- Check Promtail is reaching Loki: `docker logs promtail | grep -i error`
- Verify network connectivity: `ping 10.10.40.20`
- Check Loki is running on Jupiter: `curl http://10.10.40.20:3100/ready`

**Permission errors?**
The volumes are mounted as read-only (`:ro`), so Promtail only needs read access. If you still get permission errors, check that the `/var/log` and `/var/lib/docker` directories exist and are readable.