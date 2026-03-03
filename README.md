# Daniel's Nix Configuration

> A declarative NixOS configuration featuring a Hyprland desktop, modern development environments, and encrypted secrets management.

## Quick Links

- **[Features](docs/FEATURES.md)** - Detailed feature list
- **[Keybindings](docs/KEYBINDINGS.md)** - Complete keyboard shortcut reference
- **[Neovim](docs/NEOVIM.md)** - LSP, Treesitter, Telescope, and Fugitive setup
- **[Secrets Management](docs/SECRETS.md)** - sops-nix and Age encryption

## Repository Structure

```
nixos-config
├── hosts/              # Machine-specific configurations
│   └── weepinbell/     # Primary NixOS workstation
├── home/               # User-specific Home Manager configs
├── modules/            # Reusable configuration modules
│   ├── nixos/          # System-level NixOS modules
│   └── home-manager/   # User-space configurations
├── docs/               # Documentation
├── justfile            # Build commands
└── flake.nix           # Main flake configuration
```

## Key Dependencies

- **nixpkgs**: Latest packages from nixos-unstable
- **home-manager**: User environment management
- **sops-nix**: Encrypted secrets with Age encryption
- **catppuccin**: Beautiful pastel theme system-wide

## Highlights

### Desktop
- **Hyprland** Wayland compositor with smooth animations
- **Noctalia Shell** desktop shell (bar, notifications, lock screen)
- **Ghostty** modern terminal with tmux integration
- **NVIDIA Prime** hybrid graphics support
- **Screenshots** with Hyprshot + Satty annotation

### Development
- **Neovim** with LSP, Treesitter, Telescope, Fugitive, GitHub Copilot AI ([see full docs](docs/NEOVIM.md))
- **Tmux** with vim-aware navigation
- **Catppuccin** theme across all applications
- **Modern CLI tools** (zoxide, fzf, ripgrep, bat, eza)

## Quick Start

```bash
# Clone repository
git clone https://github.com/Danielbook/nixos-config.git
cd nixos-config

# Build and switch
just nixos-rebuild
just home-manager-switch
```

## Common Commands

```bash
# Show all available commands
just --list

# Update all packages
just flake-update

# NixOS system rebuild
just nixos-rebuild

# Home Manager switch
just home-manager-switch

# Garbage collection
just nix-gc

# Validate configuration
just flake-check
```

## Secrets Management

All secrets are encrypted with **sops-nix** and **Age encryption**:

- **Encrypted at rest** in version control
- **Runtime decryption** by NixOS
- **Fine-grained permissions** per service

See [Secrets Management Guide](docs/SECRETS.md) for details.

## Adding a New Machine

### 1. Update flake.nix

```nix
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

### 3. Create home configuration

```bash
mkdir -p home/newuser/newmachine
```

### 4. Deploy

```bash
git add .
just nixos-rebuild
just home-manager-switch
```

## Customization

### Add Packages

**NixOS system packages:**
```nix
# modules/nixos/common/default.nix
environment.systemPackages = with pkgs; [
  your-package
];
```

**User packages:**
```nix
# modules/home-manager/common/default.nix
home.packages = with pkgs; [
  your-package
];
```

## Troubleshooting

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

## Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
