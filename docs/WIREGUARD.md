# 🔐 WireGuard VPN Setup

This guide covers setting up WireGuard VPN to access your home network (OPNsense router) when away from home using NetworkManager.

## 🎯 Overview

- **VPN Type**: WireGuard (modern, fast, secure)
- **Management**: NetworkManager (GUI + CLI)
- **Home Router**: OPNsense with WireGuard server
- **Client**: coruscant (NixOS workstation), plus phone (WireGuard app)
- **Secrets**: Managed by NetworkManager's encrypted keyring (no SOPS needed)

### This Network's Actual Topology

- **WireGuard subnet**: `10.11.11.0/24` (OPNsense WG interface `wg0` = `10.11.11.1`, listens UDP `51820` on WAN)
- **coruscant client**: `10.11.11.6/32`, full tunnel (`0.0.0.0/0, ::/0`), DNS `10.11.11.1`
- **Server endpoint**: `vpn.bookorjeman.com:51820`
- **DDNS**: WAN is DHCP (IP changes), so the endpoint is a **hostname** kept current by OPNsense `os-ddclient` → Cloudflare. **Never hardcode the WAN IP** — it will break on the next lease change. See [Dynamic DNS](#-dynamic-dns-cloudflare) below.

## 📦 Prerequisites

The following packages are already installed:
- `wireguard-tools` - WireGuard utilities (wg, wg-quick)
- `networkmanagerapplet` - NetworkManager GUI (system tray icon)
- NetworkManager - Already configured in `modules/nixos/common/default.nix`

## 🚀 Setup Methods

### Method 1: GUI Import (Recommended)

1. **Get your WireGuard config file from OPNsense**
   - Download the `.conf` file from OPNsense web interface
   - Save it somewhere accessible (e.g., `~/Downloads/home-vpn.conf`)

2. **Open NetworkManager settings**
   - Click the NetworkManager icon in system tray
   - Select "Edit Connections..." or "Configure Network Connections..."

3. **Import the WireGuard configuration**
   - Click the `+` button to add a new connection
   - Select "Import a saved VPN configuration..."
   - Navigate to your `.conf` file and select it
   - Click "Import"

4. **Review and save**
   - NetworkManager will parse the config file
   - Give it a friendly name (e.g., "Home VPN")
   - Click "Save"

5. **Connect**
   - Click the NetworkManager icon
   - Select your VPN connection under "VPN Connections"
   - Wait a few seconds for connection to establish

### Method 2: CLI Import

```bash
# Import WireGuard config file
nmcli connection import type wireguard file ~/Downloads/home-vpn.conf

# Rename connection to something friendly (optional)
nmcli connection modify home-vpn connection.id "Home VPN"

# Connect to VPN
nmcli connection up "Home VPN"

# Disconnect
nmcli connection down "Home VPN"

# Check connection status
nmcli connection show --active
```

### Method 3: Manual CLI Configuration

If you don't have a `.conf` file, you can configure manually:

```bash
# Create new WireGuard connection
nmcli connection add type wireguard \
  connection.id "Home VPN" \
  connection.autoconnect no \
  wireguard.private-key "YOUR_PRIVATE_KEY" \
  ipv4.method manual \
  ipv4.addresses "10.0.0.2/24"

# Add peer (your OPNsense router)
nmcli connection modify "Home VPN" \
  wireguard.peer-routes yes \
  +wireguard.peers "public-key=ROUTER_PUBLIC_KEY, \
    endpoint=YOUR_HOME_IP:51820, \
    allowed-ips=10.0.0.0/24;192.168.1.0/24, \
    persistent-keepalive=25"

# Activate connection
nmcli connection up "Home VPN"
```

## 📋 Common WireGuard Config File Format

Your OPNsense-generated config should look something like this (values match this network):

```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY_HERE
Address = 10.11.11.6/32
DNS = 10.11.11.1

[Peer]
PublicKey = ROUTER_PUBLIC_KEY_HERE
PresharedKey = OPTIONAL_PSK_HERE
Endpoint = vpn.bookorjeman.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

**Key Fields Explained:**
- **PrivateKey**: Your client's private key (kept secret, managed by NetworkManager)
- **Address**: Your VPN IP address (this client = `10.11.11.6/32`)
- **DNS**: DNS server to use when connected (the router, `10.11.11.1`)
- **PublicKey**: Your router's public key
- **Endpoint**: **Always the DDNS hostname** `vpn.bookorjeman.com:51820`, never a raw WAN IP (DHCP, changes)
- **AllowedIPs**: Which networks to route through VPN
  - `0.0.0.0/0, ::/0` - Route ALL traffic through VPN (full tunnel — current setup)
  - For split tunnel instead: `10.11.11.0/24` (WG net) + your home LAN/VLAN subnets (`10.10.x.0/24`)
- **PersistentKeepalive**: Keep connection alive through NAT (25 seconds — required here)

## 🔧 Configuration Tips

### Split Tunnel vs Full Tunnel

**Split Tunnel (Recommended):**
```ini
AllowedIPs = 10.0.0.0/24, 192.168.1.0/24
```
- Only home network traffic goes through VPN
- Regular internet traffic uses local connection (faster)
- Good for accessing home services while traveling

**Full Tunnel:**
```ini
AllowedIPs = 0.0.0.0/0
```
- ALL internet traffic goes through home connection
- Useful for public WiFi security
- May be slower depending on home upload speed

### Auto-Connect on Boot

To automatically connect when booting (only do this at home):

```bash
# Enable auto-connect
nmcli connection modify "Home VPN" connection.autoconnect yes

# Disable auto-connect (recommended)
nmcli connection modify "Home VPN" connection.autoconnect no
```

### DNS Configuration

If you want to use your home DNS server (for local domain names):

```bash
# Set DNS servers
nmcli connection modify "Home VPN" ipv4.dns "192.168.1.1"

# Set DNS search domain
nmcli connection modify "Home VPN" ipv4.dns-search "home.local"
```

## 🌐 Dynamic DNS (Cloudflare)

The home WAN IP is **DHCP and changes** (e.g. `176.10.255.123` → `.79` on a lease renewal). A hardcoded endpoint IP silently breaks on every change. Fix: point the WireGuard endpoint at a hostname kept current by OPNsense.

### How it works

1. **OPNsense `os-ddclient`** (Services → Dynamic DNS) watches the WAN interface and pushes the current WAN IP to a Cloudflare A record.
2. Clients use the hostname `vpn.bookorjeman.com:51820` as the endpoint.
3. NetworkManager (and the phone app) **re-resolve the hostname on each reconnect**, so a `down`/`up` always lands on the current IP.

### OPNsense setup

1. System → Firmware → Plugins → install `os-ddclient`.
2. Services → Dynamic DNS → Settings → add account:
   - **Service**: `Cloudflare`
   - **Username**: `bookorjeman.com` (the zone)
   - **Password**: Cloudflare API token (token `opnsense-ddns-vpn`, scoped **DNS Edit + Zone Read** on `bookorjeman.com`, no expiry)
   - **Zone**: `bookorjeman.com`
   - **Hostname(s)**: `vpn.bookorjeman.com` (also tracks `bookorjeman.com`, `www`, `local`, `*.local`)
   - **Check ip method**: `Interface [IPv4]`, **Interface to monitor**: `WAN`
   - **Force SSL**: ✓
3. Save → force update.

### Cloudflare setup

- DNS → Records → `A` record `vpn` → WAN IP, **TTL 1 min**.
- ⚠️ **Proxy status MUST be "DNS only" (grey cloud).** The orange-cloud proxy only forwards HTTP/S and will **drop WireGuard UDP**, killing the tunnel. Verify the record never resolves to a Cloudflare IP (`104.x`/`172.67.x`).

### Verify

```bash
dig +short vpn.bookorjeman.com   # must return the real WAN IP, not a Cloudflare IP
```

## 🔍 Troubleshooting

### "VPN suddenly stopped working" → stale endpoint (most common)

Almost always the **WAN IP changed** and a client is still pointing at the old IP.

```bash
sudo wg show
```

- **`latest handshake` missing + `0 B received`** (only bytes *sent*) = packets leave but the server never answers → endpoint is stale/wrong, UDP `51820` is closed on WAN, or a key mismatch.
- Confirm the live WAN IP in OPNsense (Interfaces → Overview → WAN) and compare to `dig +short vpn.bookorjeman.com`.
- **Fix:** ensure the endpoint is the **hostname**, not a raw IP, then reconnect so it re-resolves:
  ```bash
  sudo nmcli connection modify home-vpn wireguard.peers \
    'SERVER_PUBKEY allowed-ips=0.0.0.0/0;::/0 endpoint=vpn.bookorjeman.com:51820 persistent-keepalive=25'
  nmcli connection down home-vpn; nmcli connection up home-vpn
  sudo wg show   # want: latest handshake: Now, nonzero received
  ```
- A live tunnel does **not** re-resolve the hostname mid-session — if the IP flips while connected, reconnect once.

### Check Connection Status

```bash
# List all connections
nmcli connection show

# Show active VPN connection details
nmcli connection show "Home VPN"

# Check WireGuard interface status
sudo wg show

# View recent connection logs
journalctl -u NetworkManager -n 50 --no-pager
```

### Connection Won't Establish

1. **Check endpoint is reachable:**
   ```bash
   ping your-home-ip-or-domain.com
   ```

2. **Verify port is open:**
   ```bash
   nc -zvu your-home-ip-or-domain.com 51820
   ```

3. **Check OPNsense firewall:**
   - Ensure WAN firewall rule allows UDP port 51820
   - Check WireGuard service is running in OPNsense

4. **Verify keys are correct:**
   - Double-check public/private keys match between client and server
   - Re-export config from OPNsense if unsure

### Can't Access Home Network

1. **Check allowed IPs:**
   ```bash
   nmcli connection show "Home VPN" | grep wireguard.peers
   ```
   - Ensure your home subnet is listed in allowed-ips

2. **Verify routing:**
   ```bash
   ip route show table all | grep wg
   ```

3. **Check OPNsense peer configuration:**
   - Ensure your client's public key is added in OPNsense
   - Verify allowed IPs on server side include client IP

### DNS Not Working

```bash
# Check current DNS servers
resolvectl status

# Test DNS resolution through VPN
dig @192.168.1.1 somehost.home.local

# Force DNS through VPN
nmcli connection modify "Home VPN" ipv4.dns-priority -50
```

### Connection Drops Frequently

1. **Increase persistent keepalive:**
   ```bash
   # Edit connection to set keepalive to 25 seconds
   nmcli connection modify "Home VPN" \
     wireguard.peers.persistent-keepalive 25
   ```

2. **Check if NAT is timing out:**
   - Some routers/ISPs have aggressive NAT timeouts
   - Try reducing keepalive to 15-20 seconds

3. **Monitor connection:**
   ```bash
   # Watch WireGuard stats
   watch -n 1 'sudo wg show'
   ```

## 🔐 Security Best Practices

### ✅ Do's

- **Keep private keys secure** - Never share or commit to git
- **Use strong pre-shared keys** - If OPNsense offers PSK, use it
- **Disable auto-connect** - Only connect when needed
- **Update regularly** - Keep WireGuard tools updated
- **Use split-tunnel** - Unless you need full-tunnel security
- **Rotate keys periodically** - Every 6-12 months

### ❌ Don'ts

- **Don't share config files** - They contain your private key
- **Don't use default ports** - Change from 51820 if exposed to internet
- **Don't route unnecessary traffic** - Use split-tunnel when possible
- **Don't disable firewall** - Keep OPNsense firewall rules restrictive
- **Don't expose management interfaces** - Don't route management traffic through VPN without proper security

## 📱 Mobile Setup

The same config file works on mobile devices:

- **iOS**: Install "WireGuard" app, import config via QR code or file
- **Android**: Install "WireGuard" app, import config file
- Generate separate configs for each device in OPNsense

## 🛠️ Advanced Usage

### Multiple VPN Profiles

You can have multiple WireGuard connections (work, home, etc.):

```bash
# Import multiple configs
nmcli connection import type wireguard file ~/home-vpn.conf
nmcli connection import type wireguard file ~/work-vpn.conf

# Connect to specific VPN
nmcli connection up "Home VPN"
nmcli connection up "Work VPN"
```

### Custom Routing

For advanced routing scenarios:

```bash
# Route only specific IPs through VPN
nmcli connection modify "Home VPN" \
  +ipv4.routes "192.168.1.100/32 10.0.0.1"

# Set routing metric (lower = higher priority)
nmcli connection modify "Home VPN" ipv4.route-metric 50
```

### Connection Scripts

Run scripts on connect/disconnect:

```bash
# Create dispatcher script
sudo tee /etc/NetworkManager/dispatcher.d/99-wireguard-home.sh <<'EOF'
#!/bin/bash
interface=$1
action=$2

if [[ "$CONNECTION_ID" == "Home VPN" ]]; then
  case "$action" in
    up)
      logger "Home VPN connected"
      # Add custom commands here
      ;;
    down)
      logger "Home VPN disconnected"
      # Add custom commands here
      ;;
  esac
fi
EOF

# Make executable
sudo chmod +x /etc/NetworkManager/dispatcher.d/99-wireguard-home.sh
```

## 📚 Additional Resources

- [WireGuard Official Site](https://www.wireguard.com/)
- [NetworkManager WireGuard Support](https://networkmanager.dev/docs/api/latest/settings-wireguard.html)
- [OPNsense WireGuard Documentation](https://docs.opnsense.org/manual/vpnet.html#wireguard)

## 🎯 Quick Reference

```bash
# Connect to VPN
nmcli connection up "Home VPN"

# Disconnect from VPN
nmcli connection down "Home VPN"

# Check VPN status
nmcli connection show --active | grep wireguard
sudo wg show

# Edit VPN settings (GUI)
nm-connection-editor

# View VPN logs
journalctl -u NetworkManager -f | grep -i wireguard

# Re-import config (if settings changed in OPNsense)
nmcli connection delete "Home VPN"
nmcli connection import type wireguard file ~/home-vpn.conf
```

## 📦 Declarative Setup (this repo)

The `home-vpn` tunnel on **coruscant is fully declarative** — no manual import needed. Defined in `hosts/coruscant/default.nix`:

- **Private key**: stored sops-encrypted in `hosts/coruscant/secrets.yaml` (NixOS-level sops-nix). Encrypted to two recipients: daniel's personal age key (Bitwarden-backed, recovery) and the coruscant host key.
- **Boot decrypt**: `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]` — the host SSH key decrypts the secret at activation, unattended (no Bitwarden prompt during `nixos-rebuild`).
- **Connection**: `sops.templates."home-vpn.nmconnection"` renders the NM keyfile (private key injected) directly to `/etc/NetworkManager/system-connections/home-vpn.nmconnection`. NM picks it up. `autoconnect=false` → toggle from tray / `nmcli` as usual.
- **Endpoint**: `vpn.bookorjeman.com:51820` (DDNS, see above). `10.11.11.6/32`, full tunnel.

Rebuild a machine from scratch → the tunnel reappears automatically. Nothing to re-import.

### Rotating the client key (declarative)

Write a fresh key straight into sops (never printed), then update the OPNsense peer:

```bash
cd ~/Documents/repositories/nixos-config && umask 077 && \
PRIV=$(wg genkey) && \
PUB=$(printf '%s' "$PRIV" | wg pubkey) && \
printf 'wg_home_private_key: %s\n' "$PRIV" > hosts/coruscant/secrets.yaml && \
unset PRIV && \
nix develop --command sops --encrypt --in-place hosts/coruscant/secrets.yaml && \
echo "NEW PUBLIC KEY: $PUB"
```

Then: OPNsense → VPN → WireGuard → Peers → coruscant peer (`10.11.11.6/32`) → set Public Key to the printed value → Save → Apply. Then `just nixos-rebuild` and toggle. Swapping the peer's public key is the revocation — the old private key grants nothing once the server stops accepting it.

> ⚠️ The secrets file must be `git add`ed (it's encrypted) — Nix flakes ignore untracked files, so an un-added `secrets.yaml` fails the build with "not tracked by Git".

### Machine recovery (host key lost)

If coruscant is reinstalled, its host key changes and can no longer decrypt the secret. Recover with your personal (Bitwarden) age key:

```bash
# on the rebuilt machine, get the new host age recipient
nix run nixpkgs#ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
# update the &coruscant anchor in .sops.yaml to the new value, then re-encrypt:
nix develop --command sops updatekeys hosts/coruscant/secrets.yaml
```

`updatekeys` works because your personal key (in `.sops.yaml`) can still decrypt. Worst case (machine + Bitwarden both gone): just rotate the key per above — WireGuard keys are cheap.

## 🔄 After NixOS Rebuild

On coruscant the connection is declarative (see above) — `just nixos-rebuild` renders it; no import step. For a **new host** without the declarative config, import once via NetworkManager; profiles then persist across rebuilds.
