# OpenClaw on 2017 MacBook Pro — Strategy Plan

## Context

Repurpose a 2017 Intel MacBook Pro as a dedicated OpenClaw appliance to monitor and automate the homelab:
- **coruscant** — NixOS + Hyprland workstation
- **dagobah** — Intel Mac with nix-darwin
- **servarr** — Docker Compose arr-stack (Sonarr, Radarr, Lidarr, Prowlarr, Deluge, NZBGet behind Gluetun VPN)
- **jupiter** — Traefik, Home Assistant, Mosquitto MQTT, Zigbee2MQTT, Linkding
- **TrueNAS** storage

---

## 1. Installation Strategy

### Hardware Reality Check

The 2017 Intel MacBook Pro **can run OpenClaw** but with caveats:
- **No native desktop app** — Apple Silicon only. You'll use CLI + web UI
- **Max macOS**: Ventura (13) — approaching end of security support
- **RAM**: Should be fine if 16GB model (OpenClaw core uses 300-500MB, Docker adds ~1GB)
- **Thermal**: Running 24/7 on a laptop will cause thermal stress; consider clamshell mode with a cooling pad or external fan
- **Alternative worth considering**: Install Linux (NixOS!) on the MacBook instead of macOS — better Docker support, longer security updates, fits your existing config management

### Installation Path

**Option A: macOS + Homebrew (simpler)**
1. Update to latest supported macOS (Ventura)
2. Install Node.js 22+ via Homebrew
3. Install OpenClaw CLI
4. Run as a launchd service for persistence

**Option B: NixOS on the MacBook (recommended)**
1. Install NixOS on the 2017 MacBook Pro (Intel = well-supported)
2. Use `nix-openclaw` Home Manager module for declarative installation
3. Runs as systemd user service automatically
4. Fits your existing flake architecture — add a third host (new Star Wars name!)
5. Deterministic mode via `OPENCLAW_NIX_MODE=1` (automatic with nix-openclaw)
6. Better Docker support, better container isolation, longer security update horizon

**Option C: macOS + Docker (best isolation)**
1. Run OpenClaw in a hardened Docker container on macOS
2. Use `--read-only`, `--cap-drop=ALL`, `--security-opt=no-new-privileges`
3. Strict volume mounts — only what OpenClaw needs
4. Easier to control network egress

---

## 2. Security Hardening

### Critical Security Context

OpenClaw has had serious security incidents:
- **CVE-2026-32922** (CVSS 9.9): Privilege escalation via `device.token.rotate`
- **CVE-2026-25253** (CVSS 8.8): "ClawJacked" — malicious webpages can connect to local gateway
- **30,000+ internet-facing instances** found with 63% having zero authentication
- **900+ exposed instances** found just by searching port 18789
- **7.1% of ClawHub skills** contain credential-leaking flaws; 820+ outright malicious skills discovered
- **AMOS macOS infostealer** bundled into skill uploads

### Hardening Checklist

**Network**
- [ ] **Never expose port 18789 to the internet** — gateway is the #1 attack surface
- [ ] Place the MacBook on a **dedicated VLAN** (or at minimum, firewall it from your main network)
- [ ] Use **Tailscale/WireGuard** for remote access instead of port forwarding
- [ ] Restrict outbound traffic to only: LLM API endpoints, your homelab IPs
- [ ] Block all inbound except from your trusted devices

**Gateway & Authentication**
- [ ] Set a strong gateway token — treat it like a domain admin password
- [ ] Configure `gateway.trustedProxies` correctly if using a reverse proxy (misconfiguration = auth bypass)
- [ ] Disable localhost auto-trust if running behind any reverse proxy

**Credentials**
- [ ] Use OpenClaw's **SecretRef** system — never hardcode API keys
- [ ] Prefer `exec` provider (fetches secrets at runtime) over `env` or `file`
- [ ] Consider 1Password service account for credential rotation
- [ ] Deleted credentials remain on filesystem — periodically audit `~/.openclaw/` or equivalent
- [ ] Scope API keys to minimal permissions

**Skills & Plugins**
- [ ] **Only install verified skills** — never blindly install from ClawHub
- [ ] Read skill code before installing (skills execute with full process permissions)
- [ ] Disable unnecessary MCP tools — principle of least privilege
- [ ] No sandboxing exists for skills — treat each as arbitrary code execution

**OS-Level (macOS)**
- [ ] Enable **FileVault** disk encryption
- [ ] Enable macOS firewall + **Stealth Mode**
- [ ] Create a **dedicated non-admin user** to run OpenClaw
- [ ] Disable Power Nap, Wake-on-Network Access
- [ ] Consider **Lockdown Mode** for reduced attack surface
- [ ] Disable all unnecessary services and daemons

**OS-Level (NixOS — if Option B)**
- [ ] Declarative firewall rules in NixOS config
- [ ] Dedicated system user with minimal permissions
- [ ] Read-only root filesystem (NixOS default)
- [ ] Automatic security updates via `system.autoUpgrade`

**Monitoring & Oversight**
- [ ] Enable comprehensive logging of all agent actions
- [ ] Set up **human-in-the-loop** approval for destructive actions (firewall changes, file deletions, service restarts)
- [ ] Monitor for anomalous behavior patterns
- [ ] Use `openclaw stats --live` for resource monitoring

---

## 3. Common Pitfalls to Avoid

### Installation Pitfalls
1. **macOS permissions are the #1 issue** — app must be in `/Applications` for TCC stability. Symptoms: tools silently fail, camera/screen capture returns nothing
2. **Sharp/libvips conflict** — if Homebrew has libvips globally, use `SHARP_IGNORE_GLOBAL_LIBVIPS=1`
3. **Don't sync state directory to iCloud/Dropbox** — file-lock races corrupt sessions
4. **Port 18789 conflicts** — stale PID files or other services; check before starting
5. **Setup takes time** — users report 8+ hours across multiple days for first working config

### Cost Pitfalls (the wallet killer)
6. **Default model routing is expensive** — every message (even "ok" or "thanks") hits the API
7. **Use a tiered model strategy**: cheap models (Haiku, Gemini Flash, local Ollama) for heartbeats and simple tasks; expensive models (Sonnet, GPT-4o) only for complex reasoning
8. **Run Ollama locally** (e.g., `llama3.2:1b`) for free heartbeat checks — prevents wallet bleed
9. **Budget $20-50/month** for API costs if using cloud models; unoptimized setups hit $100+/month
10. **Set spending alerts** on your API provider accounts

### Messaging Platform Pitfalls
11. **Rate limits are real**: Telegram (30/min), Discord (10/min), Signal (20/min), Slack (1/sec)
12. **Telegram 429 lockout** — excessive `setMyCommands` calls on gateway restarts; lasts ~8 minutes
13. **Multi-platform resource contention** — WhatsApp + Telegram + Discord compete for the same event loop; adding platforms causes silent failures
14. **Sessions don't persist** — closing chat stops background work. Use OpenClaw's built-in **cron scheduler** for 24/7 automation, not manual sessions
15. **WhatsApp mass messaging incident** — a bug once messaged ~20 contacts with config data. Be careful with WhatsApp integration

### Security Pitfalls
16. **Never run as root** — privilege escalation CVEs make this catastrophic
17. **Gateway localhost auto-trust** gets bypassed by reverse proxies forwarding traffic as localhost
18. **Fake extensions exist** — any OpenClaw/Moltbot VS Code extension claiming official status is fake
19. **The @clawdbot X account was hijacked** for a crypto scam — verify official sources carefully

### Operational Pitfalls
20. **OpenClaw loops and forgets context** out of the box — force it to read/update a Markdown plan file every session for predictable behavior
21. **Use `openclaw doctor`** to diagnose config issues; `openclaw doctor --fix` for auto-repair
22. **Monitor RAM** — below 2GB causes JavaScript heap crashes; Chromium automation uses 2-4GB

---

## 4. Homelab Monitoring & Automation Ideas

### Tier 1: Core Monitoring (set up first)

| What | How | Skill/Tool |
|------|-----|------------|
| Docker container health on servarr | Monitor container status, auto-alert on crash | Built-in Docker monitoring |
| Gluetun VPN health | Watch for VPN drops that break arr-stack networking | Custom skill hitting Gluetun health endpoint |
| TrueNAS pool/disk health | Check ZFS pool status, disk SMART, space usage | `truenas-skill` |
| Service availability | Ping all services (HA, Traefik, Linkding, arr-stack) | Heartbeat checks via cron |
| Disk space alerts | Alert when any host exceeds 85% | Built-in system monitoring |

### Tier 2: Smart Home Integration

| What | How | Skill/Tool |
|------|-----|------------|
| Home Assistant control | Natural language commands via Telegram/Discord | HA REST API integration |
| Zigbee device status | Monitor Z2M device availability via MQTT | `openclaw-mqtt` plugin |
| MQTT event-driven automation | React to sensor events, door/window alerts | MQTT channel plugin |
| Environmental monitoring | Temperature, humidity alerts from Zigbee sensors | Z2M -> MQTT -> OpenClaw |

### Tier 3: Media & Content Automation

| What | How | Skill/Tool |
|------|-----|------------|
| Arr-stack management | Monitor downloads, indexer health, library stats | `clawarr-suite` skill |
| Media request handling | Request movies/shows via Telegram | Sonarr/Radarr API integration |
| Download monitoring | Alert on stuck/failed downloads in Deluge/NZBGet | Custom skill |
| Library maintenance | Identify missing metadata, duplicates | Arr API queries |

### Tier 4: Infrastructure Automation

| What | How | Skill/Tool |
|------|-----|------------|
| SSL certificate monitoring | Flag expiring certs on Traefik | Certificate check skill |
| Backup verification | Test backup archives regularly, alert on failure | System integrity skill |
| NixOS update notifications | Check for nixpkgs updates, security advisories | Custom skill querying nixpkgs |
| DNS/Traefik health | Monitor reverse proxy routing health | HTTP health checks |
| Self-healing containers | Auto-restart failed Docker services on servarr | Webhook + Docker API |

### Tier 5: Quality of Life

| What | How | Skill/Tool |
|------|-----|------------|
| Daily digest | Morning summary of overnight events to Telegram | Cron-scheduled summary |
| Reddit/HN digest | Curated tech news filtered to your interests | Reddit digest skill |
| Overnight tasks | Queue up maintenance tasks to run while you sleep | Cron scheduler |
| Natural language infra queries | "How much disk space is left on TrueNAS?" via chat | Multi-skill orchestration |

### Architecture Recommendation

```
OpenClaw (MacBook Pro / dedicated host)
  |-- Discord/Telegram (alert channel)
  |-- Cron scheduler (heartbeats, digests)
  |-- Skills:
  |   |-- truenas-skill -> TrueNAS API
  |   |-- clawarr-suite -> Sonarr/Radarr/Lidarr/Prowlarr
  |   |-- HA integration -> Home Assistant REST API
  |   |-- openclaw-mqtt -> Mosquitto -> Zigbee2MQTT
  |   |-- Docker monitoring -> servarr containers
  |   +-- Custom NixOS skill -> your flake
  +-- Model routing:
      |-- Ollama local (heartbeats, simple tasks) -- FREE
      |-- Haiku/Flash (routine queries) -- CHEAP
      +-- Sonnet/GPT-4o (complex reasoning) -- ON DEMAND
```

### Complement, Don't Replace

OpenClaw is best as an **intelligent orchestrator**, not a replacement for traditional monitoring:
- Keep **Uptime Kuma** or similar for visual dashboards and historical metrics
- Use OpenClaw for **action** — it can receive alerts from Prometheus/Uptime Kuma and autonomously respond
- Think of it as: monitoring tools = eyes, OpenClaw = eyes + hands + brain

---

## 5. Verification

After setup:
1. Send a test message via Telegram/Discord and verify OpenClaw responds
2. Trigger a deliberate container failure on servarr and verify alert arrives
3. Query TrueNAS disk status via chat
4. Test a Home Assistant command (e.g., toggle a light)
5. Verify heartbeat cron runs on schedule
6. Check `openclaw stats` for resource usage
7. Confirm gateway is **not** accessible from outside your network (`nmap` from external)
8. Run `openclaw doctor` to validate configuration
9. Review logs for any unexpected outbound connections

---

## Sources

- [OpenClaw Official Website](https://openclaw.ai/)
- [OpenClaw Documentation](https://docs.openclaw.ai/)
- [OpenClaw Security Docs](https://docs.openclaw.ai/gateway/security)
- [OpenClaw Secrets Management](https://docs.openclaw.ai/gateway/secrets)
- [nix-openclaw Home Manager Module](https://github.com/openclaw/nix-openclaw)
- [OpenClaw Docker Guide](https://docs.openclaw.ai/install/docker)
- [CVE-2026-32922 Analysis](https://www.armosec.io/blog/cve-2026-32922-openclaw-privilege-escalation-cloud-security/)
- [ClawJacked Vulnerability](https://www.oasis.security/blog/openclaw-vulnerability)
- [OpenClaw Skills Marketplace Security](https://www.theregister.com/2026/02/05/openclaw_skills_marketplace_leaky_security/)
- [macOS Security and Privacy Guide](https://github.com/drduh/macOS-Security-and-Privacy-Guide)
- [truenas-skill](https://playbooks.com/skills/openclaw/skills/truenas-skill)
- [clawarr-suite](https://playbooks.com/skills/openclaw/skills/clawarr-suite)
- [openclaw-mqtt Plugin](https://github.com/hughmadden/openclaw-mqtt)
- [Home Assistant Integration](https://www.getopenclaw.ai/integrations/home-assistant)
- [7 Hard-Won Lessons for Running OpenClaw](https://medium.com/@tentenco/seven-hard-won-lessons-for-running-openclaw-without-burning-out-65e3d97d3b8d)
- [10 Things I Wish I Knew Before OpenClaw](https://x.com/ziwenco_/status/2024686968102117502)
