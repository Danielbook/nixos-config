# 🔐 WireGuard VPN Setup

This guide covers setting up WireGuard VPN to access your home network (OPNsense router) when away from home using NetworkManager.

## 🎯 Overview

- **VPN Type**: WireGuard (modern, fast, secure)
- **Management**: NetworkManager (GUI + CLI)
- **Home Router**: OPNsense with WireGuard server
- **Client**: coruscant (NixOS workstation)
- **Secrets**: Managed by NetworkManager's encrypted keyring (no SOPS needed)

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

Your OPNsense-generated config should look something like this:

```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY_HERE
Address = 10.0.0.2/24
DNS = 192.168.1.1

[Peer]
PublicKey = ROUTER_PUBLIC_KEY_HERE
PresharedKey = OPTIONAL_PSK_HERE
Endpoint = your-home-ip-or-domain.com:51820
AllowedIPs = 10.0.0.0/24, 192.168.1.0/24
PersistentKeepalive = 25
```

**Key Fields Explained:**
- **PrivateKey**: Your client's private key (kept secret, managed by NetworkManager)
- **Address**: Your VPN IP address
- **DNS**: DNS server to use when connected (usually your router)
- **PublicKey**: Your router's public key
- **Endpoint**: Your home's public IP or dynamic DNS + WireGuard port
- **AllowedIPs**: Which networks to route through VPN
  - `10.0.0.0/24` - WireGuard network
  - `192.168.1.0/24` - Your home LAN (adjust to your subnet)
  - `0.0.0.0/0` - Route ALL traffic through VPN (full tunnel)
- **PersistentKeepalive**: Keep connection alive through NAT (25 seconds recommended)

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

## 🔍 Troubleshooting

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

## 🔄 After NixOS Rebuild

After running `just nixos-rebuild`, the `wireguard-tools` package will be available. You'll need to:

1. Reboot or log out/in for changes to take full effect
2. Import your WireGuard config (one-time setup)
3. Connect to VPN as needed

Your NetworkManager connection profiles persist across rebuilds, so you only need to import once.
