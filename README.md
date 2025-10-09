# 🐧 Daniel's Nix Configuration

> A declarative, cross-platform Nix configuration supporting both NixOS (Linux) and nix-darwin (macOS), featuring modern development environments, encrypted secrets management, and comprehensive server deployment infrastructure.

## 📚 Table of Contents

- [Repository Structure](#-repository-structure)
- [Key Dependencies](#-key-dependencies)
- [Features](#-features)
- [🔐 Secrets Management](#-secrets-management)
- [Keyboard Shortcuts](#️-keyboard-shortcuts)
- [Neovim Keybindings](#-neovim-keybindings)
- [Tmux Keybindings](#-tmux-keybindings)
- [Quick Start](#-quick-start)
- [Darwin (macOS) Setup](#-darwin-macos-setup)
- [🌊 Kamino Server Infrastructure](#-kamino-server-infrastructure)
- [Server Deployment](#-server-deployment)
- [🚀 Deployment Commands](#-deployment-commands)

## 📁 Repository Structure

- 📦 `flake.nix`: Main flake configuration defining inputs and outputs for NixOS, nix-darwin, and Home Manager
- 🖥️ `hosts/`: Machine-specific configurations
  - 🐛 `weepinbell/`: Primary NixOS workstation configuration
  - 🍎 `coruscant/`: MacBook Pro (nix-darwin) configuration
  - 🌊 `kamino/`: Home automation and monitoring server
- 🏠 `home/`: User-specific Home Manager configurations  
- 📄 `files/`: Miscellaneous assets and configurations
  - 🐳 `docker-services/kamino/`: Complete Docker stack for home automation
- 🧩 `modules/`: Reusable configuration modules
  - ⚙️ `nixos/`: System-level NixOS modules (Linux)
  - 🍎 `darwin/`: System-level nix-darwin modules (macOS)
  - 👤 `home-manager/`: User-space application and service configurations (cross-platform)
- 🔧 `overlays/`: Custom Nix package overlays
- 🚀 `justfile`: Modern task runner for deployment and system management
- 🔒 `flake.lock`: Reproducible build lock file

## 🔗 Key Dependencies

- 📦 **nixpkgs**: Latest packages from `nixos-unstable` channel
- 🛡️ **nixpkgs-stable**: Stable packages from `nixos-25.05` channel  
- 🏠 **home-manager**: Declarative user environment management (cross-platform)
- 🍎 **nix-darwin**: Declarative macOS system configuration
- 🖥️ **nixos-hardware**: Hardware-optimized NixOS configurations
- 🔐 **sops-nix**: Encrypted secrets management with Age encryption
- 🎨 **catppuccin**: Beautiful pastel theme system-wide
- 📱 **nix-flatpak**: Declarative Flatpak application management (Linux)
- 🌊 **plasma-manager**: KDE Plasma configuration management (Linux)

## ✨ Features

### 🐧 Linux (NixOS) Features
- 🪟 **Hyprland**: Modern Wayland compositor with smooth animations
- 🔧 **NVIDIA Prime**: Hybrid graphics with proper offloading support
- 📋 **SwayNC**: Beautiful notification center
- 🗃️ **Albert Launcher**: Fast application launcher
- 📊 **Waybar**: Customizable status bar
- 🔒 **Hyprlock**: Secure screen locking
- 📸 **Screenshot Tools**: Built-in region and fullscreen capture
- 🎥 **Screen Recording**: Integrated recording functionality
- 👁️ **OCR Support**: Text recognition from images

### 🍎 macOS (Darwin) Features
- 🏗️ **AeroSpace**: Tiling window manager with vim-style navigation
- ⚙️ **System Defaults**: Automated macOS preferences (Dock, Finder, Trackpad)
- 🔐 **TouchID Integration**: TouchID for sudo authentication
- 🍺 **Homebrew Management**: Declarative GUI application installation
- 🖥️ **Multi-monitor Support**: Kanshi display configuration
- 🚀 **Raycast Integration**: Enhanced Spotlight replacement

### 🌐 Cross-Platform Features
- 🎨 **Catppuccin Theme**: Consistent dark theme across all applications
- 📟 **Tmux**: Terminal multiplexer with vim-aware navigation
- 👻 **Ghostty**: Modern terminal emulator with crisp rendering
- ⭐ **Starship**: Beautiful cross-shell prompt
- 📂 **Zoxide**: Smart directory jumping with frequency-based navigation
- 🏠 **Home Manager**: Declarative user environment management

### 🔐 Enterprise-Grade Security
- 🔑 **sops-nix**: Encrypted secrets management with Age encryption
- 🛡️ **Bitwarden CLI Integration**: Automated secret deployment with manual fallback
- 🔒 **Zero Secrets in Git**: All sensitive data encrypted at rest
- 🎯 **Fine-Grained Permissions**: Per-service secret access control

## 🔐 Secrets Management

This configuration uses **sops-nix** with **Age encryption** for enterprise-grade secrets management. All secrets are encrypted and safely stored in version control.

### 🔑 How It Works

1. **Age Encryption**: Uses modern Age encryption with dedicated key pairs
2. **Encrypted at Rest**: All secrets encrypted in `hosts/kamino/secrets.yaml`
3. **Runtime Decryption**: NixOS automatically decrypts secrets during deployment
4. **Bitwarden Integration**: Automated secret deployment with CLI integration

### 🚀 Secret Deployment Process

```bash
# Automated deployment with Bitwarden CLI
just deploy-kamino

# Manual secret setup (if needed)
just setup-kamino-secrets

# Check Bitwarden CLI status
just check-bw
```

### 📋 Secret Categories

- **🏠 Home Assistant**: API keys, OAuth secrets, integration tokens
- **📊 Monitoring**: Grafana passwords, InfluxDB tokens
- **🔗 Networking**: Cloudflare API tokens, Traefik credentials
- **🌐 ESPHome**: Device API keys, OTA passwords, WiFi credentials
- **📡 Services**: UniFi passwords, Docker registry tokens

### 🔧 Adding New Secrets

1. **Define in NixOS configuration**:
   ```nix
   sops.secrets."kamino/service/new-secret" = {
     owner = "root";
     group = "docker";
     mode = "0440";
   };
   ```

2. **Add to encrypted secrets file** using `sops` or Bitwarden CLI
3. **Reference in Docker Compose**:
   ```yaml
   environment:
     - NEW_SECRET_FILE=/run/secrets/kamino-service-new-secret
   ```

## ⌨️ Keyboard Shortcuts

**Main Modifier:** `Super` (Windows key)

### 🚀 Applications
| Shortcut | Action |
|----------|--------|
| `Super + Shift + Enter` | 🖥️ Open terminal (Ghostty) |
| `Super + Shift + F` | 📁 Open file manager (Nautilus) |
| `Super + A` | 🗃️ Show applications menu |
| `Ctrl + Space` | 🔍 Toggle Albert launcher |
| `Super + N` | 📋 Toggle notifications (SwayNC) |

### 🪟 Window Management  
| Shortcut | Action |
|----------|--------|
| `Super + Q` | ❌ Kill active window |
| `Ctrl + Alt + Q` | 🚪 Exit Hyprland |
| `Super + F` | 📌 Toggle floating mode |
| `Super + M` | 📺 Toggle fullscreen |
| `Super + Return` | 🔄 Swap with master window |
| `Super + O` | 🔄 Cycle layout orientation |

### 🧭 Navigation (Vim-style)
| Shortcut | Action |
|----------|--------|
| `Super + h/j/k/l` | 👆 Move focus (left/down/up/right) |
| `Super + Shift + ←→↑↓` | 📏 Resize window |
| `Super + 1-9,0` | 🏠 Switch to workspace 1-10 |
| `Super + Shift + 1-9,0` | 📦 Move window to workspace 1-10 |

### 📸 Screenshots & Tools
| Shortcut | Action |
|----------|--------|
| `Super + Shift + S` | 📷 Screenshot region |
| `Super + Ctrl + S` | 🖼️ Screenshot full screen |  
| `Super + Shift + R` | 🎥 Start screen recording |
| `Super + Shift + C` | 🎨 Color picker |
| `Alt + Shift + 2` | 👁️ OCR text recognition |

### 🎵 System Controls
| Shortcut | Action |
|----------|--------|
| `Volume Keys` | 🔊 Adjust system volume |
| `Brightness Keys` | 💡 Adjust screen brightness |
| `Shift + Brightness` | ⌨️ Adjust keyboard backlight |
| `Ctrl + Alt + L` | 🔒 Lock screen |

## 📝 Neovim Keybindings

**Leader Key:** `Space`

### 📁 File Management
| Shortcut | Action |
|----------|--------|
| `<leader>pv` | 📂 Open file explorer (netrw) |
| `<leader>ff` | 🔍 Find files (Telescope) |
| `<leader>fb` | 📄 Find buffers (Telescope) |
| `Ctrl + p` | 🗂️ Find git files (Telescope) |
| `<leader>gw` | 🔎 Live grep search (Telescope) |
| `<leader>fh` | ❓ Help tags (Telescope) |

### 🪟 Window Navigation
| Shortcut | Action |
|----------|--------|
| `Ctrl + h/j/k/l` | ↔️ Navigate between panes |
| `<leader>w` | 💾 Save file |
| `<leader>q` | 🚪 Quit |
| `Ctrl + n` | 🌳 Toggle Neo-tree (left) |
| `<leader>bf` | 📋 Show buffers (Neo-tree float) |

### 🔍 Search & Replace
| Shortcut | Action |
|----------|--------|
| `<leader>fw` | 🎯 Search word under cursor |
| `<leader>fW` | 🎯 Search WORD under cursor |
| `<leader>gd` | 🔗 Go to definition (LSP) |
| `<leader>gr` | 📚 Find references (LSP) |

### 📝 Text Editing
| Shortcut | Action |
|----------|--------|
| `<leader>p` | 📋 Paste without overwriting register |
| `<leader>y` | 📄 Yank to system clipboard |
| `<leader>Y` | 📄 Yank line to system clipboard |
| `Ctrl + d/u` | ⬇️⬆️ Half page down/up (centered) |
| `Ctrl + f/b` | 📃 Full page down/up (centered) |

### 🛠️ LSP & Development
| Shortcut | Action |
|----------|--------|
| `K` | 📖 Show hover documentation |
| `<leader>vws` | 🔍 Workspace symbol search |
| `<leader>vd` | ⚠️ Open diagnostic float |
| `<leader>ca` | ⚡ Code actions |
| `<leader>rn` | ✏️ Rename symbol |
| `Ctrl + h` | 📝 Signature help (insert mode) |
| `[d` / `]d` | ⬅️➡️ Navigate diagnostics |
| `<leader>bf` | 🎨 Format buffer |

### 📚 Utilities
| Shortcut | Action |
|----------|--------|
| `<leader>u` | 🌳 Toggle undo tree |
| `Ctrl + c` | 🔄 Escape (insert mode) |

## 📟 Tmux Keybindings

**Prefix Key:** `Ctrl + Q`

### 🪟 Window & Session Management
| Shortcut | Action |
|----------|--------|
| `Ctrl + Q` then `c` | ➕ Create new window |
| `Ctrl + Q` then `r` | ✏️ Rename current window |
| `Ctrl + Q` then `R` | 🔄 Reload tmux config |
| `Ctrl + Q` then `d` | 🚪 Detach from session |
| `Ctrl + Q` then `n` | ➡️ Next window |
| `Ctrl + Q` then `p` | ⬅️ Previous window |
| `Ctrl + Q` then `1-9` | 🔢 Switch to window number |

### 🔄 Pane Management
| Shortcut | Action |
|----------|--------|
| `Ctrl + Q` then `v` | ↔️ Split pane vertically |
| `Ctrl + Q` then `s` | ↕️ Split pane horizontally |
| `Ctrl + h/j/k/l` | 🧭 Navigate panes (vim-style) |
| `Shift + ←→↑↓` | 📏 Resize panes |
| `Ctrl + Q` then `x` | ❌ Close current pane |

### 🔧 Utilities
| Shortcut | Action |
|----------|--------|
| `Ctrl + Q` then `Ctrl + L` | 🧹 Clear screen |
| `Ctrl + F` | 📁 Open project selector |
| Mouse scroll | 📜 Scroll through history |

### 📋 Copy Mode (Vi-style)
| Shortcut | Action |
|----------|--------|
| `Ctrl + Q` then `[` | 📋 Enter copy mode |
| `Space` | 📍 Start selection (in copy mode) |
| `Enter` | 📄 Copy selection (in copy mode) |
| `Ctrl + Q` then `]` | 📥 Paste |

## 🚀 Quick Start

### Initial Setup
```bash
# Clone the repository
git clone https://github.com/Danielbook/nixos-config.git
cd nixos-config

# Build and switch (requires sudo)
just nixos-rebuild

# Apply Home Manager configuration  
just home-manager-switch
```

### 🔧 Adding a New Machine

1. **📝 Update `flake.nix`**:
   ```nix
   # Add to users configuration
   users = {
     daniel = { /* existing config */ };
     newuser = {
       avatar = ./files/avatar/face;
       email = "user@example.com";
       fullName = "New User";
       name = "newuser";
     };
   };
   
   # Add machine configurations
   nixosConfigurations = {
     weepinbell = mkNixosConfiguration "weepinbell" "daniel";
     newmachine = mkNixosConfiguration "newmachine" "newuser";
   };
   
   homeConfigurations = {
     "daniel@weepinbell" = mkHomeConfiguration "x86_64-linux" "daniel" "weepinbell";  
     "newuser@newmachine" = mkHomeConfiguration "x86_64-linux" "newuser" "newmachine";
   };
   ```

2. **🖥️ Create System Configuration**:
   ```bash
   mkdir -p hosts/newmachine
   sudo nixos-generate-config --show-hardware-config > hosts/newmachine/hardware-configuration.nix
   ```
   
   Create `hosts/newmachine/default.nix`:
   ```nix
   { hostname, nixosModules, ... }:
   {
     imports = [
       ./hardware-configuration.nix
       "${nixosModules}/common"
       "${nixosModules}/desktop/hyprland"
       "${nixosModules}/nvidia"  # If needed
     ];
     
     networking.hostName = hostname;
     system.stateVersion = "25.05";
   }
   ```

3. **🏠 Create Home Configuration**:
   ```bash
   mkdir -p home/newuser/newmachine
   ```
   
   Create `home/newuser/newmachine/default.nix`:
   ```nix
   { nhModules, ... }:
   {
     imports = [
       "${nhModules}/common"
       "${nhModules}/desktop/hyprland"
     ];
     
     home.stateVersion = "25.05";
   }
   ```

4. **🚀 Deploy**:
   ```bash
   git add .
   just nixos-rebuild
   just home-manager-switch
   ```

## 🍎 Darwin (macOS) Setup

This configuration supports macOS through nix-darwin, providing declarative system management for your MacBook Pro.

### Prerequisites

1. **macOS Requirements**: Ensure you're running macOS 10.15 (Catalina) or later
2. **Xcode Command Line Tools**: Install if not already present:
   ```bash
   xcode-select --install
   ```
3. **Admin Privileges**: Ensure you have administrator access

### 🚀 Quick Bootstrap (Recommended)

1. **Clone this repository**:
   ```bash
   git clone https://github.com/Danielbook/nixos-config.git
   cd nixos-config
   ```

2. **Set your hostname** (optional, if different from `coruscant`):
   ```bash
   sudo scutil --set HostName coruscant
   sudo scutil --set LocalHostName coruscant
   sudo scutil --set ComputerName "Coruscant"
   ```

3. **Run the automated bootstrap**:
   ```bash
   just bootstrap-mac
   ```

4. **Restart your terminal** and verify installation:
   ```bash
   darwin-rebuild --version
   home-manager --version
   ```

### 🛠️ Manual Setup

If you prefer manual installation or encounter issues with the bootstrap:

1. **Install Nix**:
   ```bash
   curl -L https://nixos.org/nix/install | sh -s -- --daemon
   ```

2. **Source Nix profile** (or restart terminal):
   ```bash
   . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
   ```

3. **Install nix-darwin**:
   ```bash
   just install-nix-darwin
   ```

4. **Install Home Manager**:
   ```bash
   just home-manager-switch
   ```

### 📱 Daily Usage

- **Update system configuration**: `just darwin-rebuild`
- **Update user environment**: `just home-manager-switch`  
- **Update all packages**: `just flake-update`

### 📁 Configuration Structure

```
├── hosts/coruscant/            # MacBook Pro system configuration
├── modules/darwin/             # Darwin-specific modules
│   ├── common/                 # Base macOS system settings
│   └── desktop/                # Desktop environment setup
├── home/daniel/coruscant/      # Home Manager configuration
└── modules/home-manager/       # Cross-platform user configurations
```

### 🍺 Installed Applications

**Via Nix**: Development tools (git, neovim, tmux), terminal utilities, programming languages

**Via Homebrew**: 
- Raycast (Enhanced Spotlight)
- Spotify (Music streaming)
- Discord (Communication)
- Obsidian (Note taking)
- Visual Studio Code (Code editor)

### ⚙️ Automated System Preferences

The configuration automatically configures:
- **Dock**: Auto-hide, no recent apps, optimal tile size
- **Finder**: Show extensions, path bar, status bar
- **Trackpad**: Tap to click, three-finger drag
- **Keyboard**: Caps Lock → Escape mapping
- **Security**: TouchID for sudo authentication
- **Interface**: Dark mode, reduced motion
- **Screenshots**: Saved to Desktop as PNG

### 🪟 AeroSpace Window Management

- **Alt + Shift + Enter**: Open terminal
- **Alt + h/j/k/l**: Navigate windows (vim-style)
- **Alt + Shift + h/j/k/l**: Move windows
- **Alt + 1-9**: Switch workspaces
- **Alt + Shift + 1-9**: Move window to workspace

### 🔧 Troubleshooting

**"command not found" after installation**: Restart terminal or source nix profile

**Permission denied errors**: Ensure admin privileges and try with `sudo` for system operations

**Build failures**: Verify hostname matches configuration and check macOS compatibility

### 🎨 Customization

- **System packages**: Add to `modules/darwin/common/default.nix`
- **User packages**: Add to `home/daniel/coruscant/default.nix`
- **Homebrew apps**: Add to `hosts/coruscant/default.nix`
- **System preferences**: Modify `system.defaults` in Darwin modules

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

## 🖥️ Server Deployment

This configuration supports both desktop workstations and production-ready headless servers with automated deployment.

### 🌟 Available Server Configurations

- **🌊 Kamino**: Home automation and monitoring server (Home Assistant, Grafana, Traefik)
- **🏜️ Tatooine**: Coming soon...  
- **❄️ Hoth**: Coming soon...

### 🚀 Remote Deployment with nixos-anywhere

Deploy NixOS servers remotely with full automation:

#### 1. **🖥️ Prepare Target Machine**

Create VM or physical server with NixOS minimal ISO:

```bash
# On the target machine console
sudo systemctl start sshd
passwd nixos  # Set temporary password for nixos user
ip addr show  # Note the IP address for deployment
```

#### 2. **🚢 Deploy Kamino Server**

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

#### 3. **🔧 Manual Secret Setup** (if Bitwarden unavailable)

```bash
# Set up secrets manually if Bitwarden CLI fails
just setup-kamino-secrets

# Check Bitwarden CLI status and configuration
just check-bw
```

#### 4. **✅ Verify Deployment**

```bash
# Check running services
ssh root@10.10.40.20 'docker ps'

# Verify Home Assistant
curl -k https://homeassistant.local.bookorjeman.com

# Check service logs
ssh root@10.10.40.20 'docker-compose -f /srv/homeassistant-stack/docker-compose.yaml logs'
```

### 📦 Data Migration (Optional)

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

### ⚙️ Server Features

- **🔒 Secure by Default**: SSH hardening, minimal attack surface
- **🐳 Container Orchestration**: Auto-discovery and management of Docker services
- **🔥 Smart Firewalls**: Host-specific port configurations
- **📊 Built-in Monitoring**: System metrics and log aggregation
- **🎯 Minimal Footprint**: Server-optimized package selection
- **🔄 Self-Healing**: Systemd service recovery and health checks

### 🛠️ Advanced Deployment Options

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

### 📋 Available Commands

```bash
# Show all available commands
just --list

# Show detailed help with examples
just help
```

### 🏠 Local System Management

```bash
# NixOS/Linux systems
just nixos-rebuild          # Rebuild NixOS configuration
just home-manager-switch    # Switch Home Manager configuration

# macOS (Darwin) systems  
just darwin-rebuild         # Rebuild Darwin configuration
just bootstrap-mac          # Complete macOS setup from scratch
```

### 🛠️ Development & Maintenance

```bash
just flake-update           # Update all flake inputs to latest
just flake-check            # Validate flake configuration  
just nix-gc                 # Run garbage collection to free space
```

### 🖥️ Server Deployment

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

### 🔧 Setup & Utilities

```bash
# Initial setup commands
just install-nix            # Install Nix package manager
just install-nix-darwin     # Install nix-darwin (macOS)

# Bitwarden CLI integration
just check-bw               # Verify Bitwarden CLI setup and status
```

### 🎯 Example Workflows

#### 🖥️ **Setting up a new workstation**:
```bash
git clone https://github.com/Danielbook/nixos-config.git
cd nixos-config
just nixos-rebuild
just home-manager-switch
```

#### 🍎 **macOS bootstrap**:
```bash
just bootstrap-mac          # Complete macOS setup
```

#### 🌊 **Deploy Kamino server**:
```bash
just deploy-kamino          # Deploy home automation infrastructure
```

#### 🔄 **Update everything**:
```bash
just flake-update           # Update package versions
just nixos-rebuild          # Apply updates to system
just home-manager-switch    # Apply updates to user environment
```

### 🚀 Advanced Features

- **📡 Connectivity Checks**: Automatic server reachability validation
- **🔐 Bitwarden Integration**: Automated secret deployment with CLI fallback  
- **⚡ Parallel Execution**: Multiple operations run concurrently when possible
- **🎯 Error Handling**: Comprehensive error checking with helpful messages
- **📊 Progress Feedback**: Real-time deployment status and logging

### 💡 Migration from Makefile

This project migrated from Make to Just for enhanced features:

| Old (Make) | New (Just) | Improvements |
|------------|------------|--------------|
| `make deploy-kamino` | `just deploy-kamino` | ✅ Better error handling |
| `make nixos-rebuild` | `just nixos-rebuild` | ✅ Bitwarden integration |
| `make help` | `just help` | ✅ Enhanced documentation |
| `make bootstrap-mac` | `just bootstrap-mac` | ✅ Cleaner syntax |

---

## 🎉 Getting Started

Ready to deploy your own infrastructure? 

1. **🍴 Fork this repository**
2. **⚙️ Customize configurations** for your hardware and services  
3. **🔑 Set up your own Age keys** for secrets management
4. **🚀 Deploy with confidence** using the automated tooling

The entire infrastructure is declarative, reproducible, and production-tested. Welcome to the future of system administration! 🌟

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Feel free to use this configuration as inspiration for your own setup! 🚀