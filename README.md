# Daniel's Nix Configuration

> Declarative, flake-based NixOS configuration with a dendritic (multi-host-ready) architecture. A shared trunk branches into host-type-specific layers: desktop hosts grow compositor branches, servers stay lean on the trunk.

## Quick Links

- **[Architecture](docs/ARCHITECTURE.md)** - Module patterns, specialArgs, and import conventions
- **[CLI Tools](docs/CLI-TOOLS.md)** - All CLI tools with project links
- **[Features](docs/FEATURES.md)** - Detailed feature list
- **[Keybindings](docs/KEYBINDINGS.md)** - Complete keyboard shortcut reference
- **[Neovim](docs/NEOVIM.md)** - LSP, Treesitter, Telescope, and Fugitive setup
- **[Secrets](docs/SECRETS.md)** - sops-nix and Age encryption

## Repository Structure

```
nixos-config
├── hosts/              # Machine-specific system configurations
│   ├── coruscant/      # Primary workstation (NixOS + Hyprland)
│   └── dagobah/        # Intel Mac (nix-darwin)
├── home/               # User-specific Home Manager configs
│   └── daniel/
│       ├── coruscant/  # Host-specific HM overrides + Noctalia settings
│       └── dagobah/    # macOS home config
├── modules/
│   ├── nixos/          # NixOS system-level modules
│   │   ├── common/     # Universal trunk (all hosts)
│   │   ├── desktop/    # Desktop layer: common/ + hyprland/
│   │   ├── graphics/   # Per-host GPU configuration
│   │   └── services/   # Opt-in services (tlp, audio, usb-serial)
│   ├── nix-darwin/     # macOS system-level modules
│   │   └── common/     # macOS trunk (Homebrew, system defaults)
│   └── home-manager/   # User-space modules
│       ├── common/     # Universal trunk (CLI tools, 20+ programs)
│       ├── desktop/    # Desktop layer: common/ (GUI apps) + hyprland/
│       ├── programs/   # Individual program modules
│       ├── services/   # Individual service modules
│       └── scripts/    # CLI scripts + desktop/ scripts
├── overlays/           # Nixpkgs overlays (vim plugins from source)
├── docs/               # Documentation
├── justfile            # Task runner for builds, formatting, and linting
└── flake.nix           # Flake configuration and inputs
```

### Dendritic Module Layers

```
common (all hosts: nix settings, SSH, Docker, CLI tools)
├── desktop/common (desktop hosts: PipeWire, Bluetooth, fonts, GUI apps)
│   ├── desktop/hyprland (Hyprland compositor + services)
│   └── desktop/<other> (future: Kodi, etc.)
└── (servers skip desktop entirely)
```

## Flake Inputs

| Input | Purpose |
|-------|---------|
| **nixpkgs** | nixos-unstable (bleeding edge) |
| **home-manager** | User environment and dotfile management |
| **sops-nix** | Encrypted secrets with Age encryption |
| **catppuccin** | System-wide Catppuccin Macchiato theming |
| **noctalia** | Desktop shell (bar, notifications, lock screen) |
| **awww** | Wayland wallpaper daemon |
| **hyprdynamicmonitors** | Dynamic monitor configuration for Hyprland |
| **spicetify-nix** | Declarative Spotify theming |
| **zen-browser** | Firefox-based privacy browser |
| **nix-flatpak** | Declarative Flatpak management (v0.6.0) |
| **worktrunk** | Git worktree management CLI |
| **nix-darwin** | macOS system management |
| **walls** | Curated wallpaper collection |

## Highlights

### Desktop
- **Hyprland** Wayland compositor with smooth animations and NVIDIA Prime support
- **Noctalia Shell** desktop shell (bar, notifications, lock screen, wallpaper engine)
- **awww** wallpaper daemon with curated wallpaper collection
- **Ghostty** + **Kitty** + **Alacritty** terminal emulators
- **Hyprshot** + **Satty** screenshot and annotation pipeline
- **EasyEffects** audio processing with custom presets
- **Flatpak** apps managed declaratively via nix-flatpak
- **Hypridle** with robust suspend/resume lockscreen recovery

### Development
- **Neovim** with LSP, Treesitter, Telescope, Fugitive, GitHub Copilot ([docs](docs/NEOVIM.md))
- **AI coding agents**: Claude Code, Codex, OpenCode
- **Git** with SSH commit signing and GitLab conditional includes
- **Jujutsu** modern VCS alongside Git
- **Tmux** with vim-aware navigation
- **Direnv** + **Nix develop** for per-project shells

### CLI Tools
atuin, bat, btop, carapace, dust, eza, fastfetch, fd, fzf, jq, lazydocker, lazygit, ripgrep, sesh, starship, television, yazi, zoxide, zsh

### Theming
- **Catppuccin Macchiato** (lavender accent) across all applications
- **Spicetify** Spotify theming integrated with Noctalia

## Quick Start

```bash
git clone https://github.com/Danielbook/nixos-config.git
cd nixos-config

just nixos-rebuild
just home-manager-switch
```

## Commands

```bash
just --list               # Show all available commands

# Build
just nixos-rebuild        # NixOS system rebuild (Linux)
just darwin-rebuild       # nix-darwin system rebuild (macOS)
just home-manager-switch  # Home Manager switch
just flake-check          # Validate flake configuration
just flake-update         # Update all flake inputs
just nix-gc               # Garbage collection

# Code quality
just format               # Format Nix files (nixfmt-rfc-style)
just lint                 # Run statix + deadnix
just check-all            # Format + lint + flake check

# Utilities
just noctalia-sync        # Sync Noctalia UI changes to repo
```

## Secrets Management

All secrets are encrypted with **sops-nix** and **Age encryption**:

- Encrypted at rest in version control
- Runtime decryption by NixOS
- Fine-grained permissions per service

See [Secrets Management Guide](docs/SECRETS.md) for details.

## Troubleshooting

```bash
# Validate configuration
just flake-check

# Show detailed error trace
nixos-rebuild switch --show-trace

# Check Home Manager logs
journalctl --user -u home-manager-${USER}.service
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
