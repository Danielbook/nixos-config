# 🐧 Daniel's Nix Configuration

> A declarative, cross-platform Nix configuration supporting both NixOS (Linux) and nix-darwin (macOS), featuring modern development environments, encrypted secrets management, and comprehensive server deployment infrastructure.

## 📚 Quick Links

- **[✨ Features](docs/FEATURES.md)** - Detailed feature lists by platform
- **[⌨️ Keybindings](docs/KEYBINDINGS.md)** - Complete keyboard shortcut reference
- **[🔐 Secrets Management](docs/SECRETS.md)** - sops-nix and Bitwarden integration
- **[🖥️ Server Deployment](docs/SERVER.md)** - Kamino infrastructure and nixos-anywhere
- **[🍎 macOS Setup](docs/MACOS.md)** - nix-darwin and AeroSpace configuration

## 📁 Repository Structure

```
📦 nixos-config
├── 🖥️ hosts/              # Machine-specific configurations
│   ├── weepinbell/        # Primary NixOS workstation
│   ├── coruscant/         # MacBook Pro (nix-darwin)
│   └── kamino/            # Home automation server
├── 🏠 home/               # User-specific Home Manager configs
├── 🧩 modules/            # Reusable configuration modules
│   ├── nixos/             # System-level NixOS modules
│   ├── darwin/            # System-level nix-darwin modules
│   └── home-manager/      # User-space configurations
├── 📄 docs/               # Documentation
├── 🔧 justfile            # Deployment commands
└── 🔒 flake.nix          # Main flake configuration
```

## 🔗 Key Dependencies

- **❄️ nixpkgs**: Latest packages from nixos-unstable
- **🏠 home-manager**: User environment management
- **🍎 nix-darwin**: macOS system configuration
- **🔐 sops-nix**: Encrypted secrets with Age encryption
- **🎨 catppuccin**: Beautiful pastel theme system-wide

## ✨ Highlights

### 🐧 Linux (NixOS)
- **Hyprland** Wayland compositor with smooth animations
- **HyprPanel** floating status bar with built-in notification center
- **Ghostty** modern terminal with tmux integration
- **NVIDIA Prime** hybrid graphics support
- **Screenshots** with Hyprshot + Satty annotation

### 🍎 macOS (Darwin)
- **AeroSpace** tiling window manager
- **Automated system preferences** (Dock, Finder, Trackpad)
- **TouchID** for sudo authentication
- **Homebrew** declarative GUI app management

### 🌐 Cross-Platform
- **Neovim** with LSP, Treesitter, Telescope
- **Tmux** with vim-aware navigation
- **Catppuccin** theme across all applications
- **Modern CLI tools** (zoxide, fzf, ripgrep, bat, eza)

### 🖥️ Server Infrastructure
- **Kamino** home automation server
- **Home Assistant** smart home hub
- **Grafana** + **Prometheus** monitoring
- **Traefik** reverse proxy with SSL
- **Automated deployment** with nixos-anywhere

## 🚀 Quick Start

### NixOS / Linux

```bash
# Clone repository
git clone https://github.com/Danielbook/nixos-config.git
cd nixos-config

# Build and switch
just nixos-rebuild
just home-manager-switch
```

### macOS

```bash
# Clone repository
git clone https://github.com/Danielbook/nixos-config.git
cd nixos-config

# Automated bootstrap
just bootstrap-mac
```

### Server Deployment

```bash
# Deploy Kamino home automation server
just deploy-kamino
```

## 🔧 Common Commands

```bash
# Show all available commands
just --list

# Update all packages
just flake-update

# NixOS system rebuild
just nixos-rebuild

# Home Manager switch
just home-manager-switch

# macOS rebuild
just darwin-rebuild

# Deploy server
just deploy-kamino

# Garbage collection
just nix-gc

# Validate configuration
just flake-check
```

## 🔐 Secrets Management

All secrets are encrypted with **sops-nix** and **Age encryption**:

- **Encrypted at rest** in version control
- **Automated deployment** via Bitwarden CLI
- **Runtime decryption** by NixOS
- **Fine-grained permissions** per service

See [Secrets Management Guide](docs/SECRETS.md) for details.

## 📝 Adding a New Machine

### 1. Update flake.nix

```nix
users = {
  newuser = {
    avatar = ./files/avatar/face;
    email = "user@example.com";
    fullName = "New User";
    name = "newuser";
  };
};

nixosConfigurations = {
  newmachine = mkNixosConfiguration "newmachine" "newuser";
};

homeConfigurations = {
  "newuser@newmachine" = mkHomeConfiguration "x86_64-linux" "newuser" "newmachine";
};
```

### 2. Create host configuration

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
  ];

  networking.hostName = hostname;
  system.stateVersion = "25.05";
}
```

### 3. Create home configuration

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

### 4. Deploy

```bash
git add .
just nixos-rebuild
just home-manager-switch
```

## 🎯 Platform-Specific Guides

- **[Linux Setup & Features](docs/FEATURES.md#-linux-nixos-features)**
- **[macOS Setup & Features](docs/MACOS.md)**
- **[Server Deployment](docs/SERVER.md)**
- **[Complete Keybindings](docs/KEYBINDINGS.md)**

## 🛠️ Customization

### Add Packages

**NixOS system packages:**
```nix
# modules/nixos/common/default.nix
environment.systemPackages = with pkgs; [
  your-package
];
```

**User packages (cross-platform):**
```nix
# modules/home-manager/common/default.nix
home.packages = with pkgs; [
  your-package
];
```

**macOS Homebrew apps:**
```nix
# hosts/coruscant/default.nix
homebrew.casks = [
  "your-app"
];
```

## 🔍 Troubleshooting

### Build Failures

```bash
# Validate configuration
just flake-check

# Show detailed error trace
nixos-rebuild switch --show-trace
```

### Home Manager Issues

```bash
# Check home-manager logs
journalctl --user -u home-manager-${USER}.service

# Rebuild with verbose output
home-manager switch --show-trace
```

### Server Deployment Issues

```bash
# Test connectivity
ping kamino-ip-address

# Check deployment logs
just deploy-kamino --show-trace
```

## 📚 Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
- [nixos-anywhere Guide](https://github.com/nix-community/nixos-anywhere)

## 🎉 Getting Started

Ready to deploy your own infrastructure?

1. **🍴 Fork this repository**
2. **⚙️ Customize** configurations for your hardware
3. **🔑 Set up** your own Age keys for secrets
4. **🚀 Deploy** with confidence using automated tooling

The entire infrastructure is declarative, reproducible, and production-tested!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ using Nix** | **Themed with 🎨 Catppuccin**
