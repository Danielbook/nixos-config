# Claude Code Instructions

## Repository Overview
This is **Daniel's NixOS Configuration Repository** - a declarative, flake-based system configuration supporting:
- **3 hosts**:
  - `weepinbell` (Primary NixOS workstation with Hyprland)
  - `coruscant` (MacBook Pro with nix-darwin)
  - `kamino` (Home automation server)
- **User**: daniel (Daniel Book, daniel@bookorjeman.se)
- **Architecture**: x86_64-linux primary, with cross-platform support

### Key Flake Inputs (Current Versions)
- **nixpkgs**: nixos-unstable (bleeding edge packages)
- **nixpkgs-stable**: nixos-25.05 (for compatibility)
- **home-manager**: User environment management (follows nixpkgs)
- **nix-darwin**: macOS system configuration
- **plasma-manager**: KDE Plasma configuration
- **catppuccin**: System-wide theming
- **sops-nix**: Age-encrypted secrets management
- **disko**: Declarative disk partitioning
- **nix-flatpak**: v0.6.0 (pinned version)
- **swwwitch**: Custom wallpaper switcher for swww (written in Go)
- **hypr-binds**: Fuzzel-based Hyprland keybindings viewer
- **walls**: dharmx wallpaper collection (used by swwwitch)

### Repository Structure
```
📦 nixos-config/
├── 🖥️ hosts/              # Machine-specific configurations
│   ├── weepinbell/        # Primary NixOS workstation (Hyprland + HyprPanel)
│   ├── coruscant/         # MacBook Pro (nix-darwin + AeroSpace)
│   └── kamino/            # Home automation server
├── 🏠 home/               # User-specific Home Manager configs per host
├── 🧩 modules/
│   ├── nixos/             # System-level NixOS modules
│   ├── darwin/            # System-level nix-darwin modules
│   └── home-manager/      # User-space cross-platform configs
├── 📁 files/              # Static files (avatars, configs, etc.)
├── 📄 docs/               # Comprehensive documentation
│   ├── FEATURES.md        # Platform-specific feature lists
│   ├── KEYBINDINGS.md     # Complete keyboard shortcuts
│   ├── NEOVIM.md          # LSP, Treesitter, Telescope setup
│   ├── SECRETS.md         # sops-nix and Bitwarden integration
│   ├── SERVER.md          # Kamino infrastructure details
│   └── MACOS.md           # nix-darwin and AeroSpace setup
├── 🔧 overlays/           # Custom package overlays
├── 🔧 justfile            # All deployment commands (use these!)
├── 🔒 flake.nix          # Main flake configuration
└── 📝 CLAUDE.md          # This file - keep it updated!
```

### Tech Stack Highlights
**Linux (Hyprland Desktop):**
- Hyprland (Wayland compositor)
- HyprPanel (floating status bar with notification center)
- Ghostty (modern terminal with tmux)
- Neovim (with LSP, Treesitter, Telescope, Copilot)
- NVIDIA Prime hybrid graphics
- Hyprshot + Satty (screenshots)

**macOS (Darwin):**
- AeroSpace (tiling window manager)
- Homebrew declarative app management
- TouchID sudo authentication
- Automated system preferences

**Cross-Platform Tools:**
- tmux (with vim-aware navigation)
- zoxide, fzf, ripgrep, bat, eza
- Catppuccin theming everywhere

**Server (Kamino):**
- Home Assistant
- Grafana + Prometheus monitoring
- Traefik reverse proxy
- Automated deployment via nixos-anywhere

## Build Commands
- **Always use `just nixos-rebuild` instead of `sudo nixos-rebuild switch`**
- **Always use `just home-manager-switch` instead of `home-manager switch`**
- **Use `just darwin-rebuild` for macOS builds**
- **Use `just flake-update` to update all flake inputs**
- **Use `just flake-check` to validate configuration before building**

These just targets provide consistent build behavior and proper error handling.

### Common Just Commands
- `just --list` - Show all available commands
- `just deploy-kamino` - Deploy Kamino server
- `just nix-gc` - Garbage collection
- `just bootstrap-mac` - Automated macOS setup

## Version Management
- **nixpkgs follows nixos-unstable** - expect latest packages and APIs
- **Check flake.lock for exact input revisions** before suggesting deprecated patterns
- **nix-flatpak is pinned to v0.6.0** - don't suggest v0.5.x or v0.7.x+ APIs
- **When suggesting Nix patterns**: Assume modern flakes syntax (not legacy channels)
- **State versions**: System is on 25.05, respect this for compatibility

### Avoiding Deprecated Patterns
- ❌ DON'T use `nixos-rebuild switch` directly (use `just nixos-rebuild`)
- ❌ DON'T use old-style `nix-env -i` (use flake packages)
- ❌ DON'T suggest `channels` (this is a flake-based config)
- ❌ DON'T use `with pkgs;` excessively (prefer explicit `pkgs.`)
- ✅ DO check flake.lock for exact package versions
- ✅ DO suggest `nix search nixpkgs <package>` for finding packages
- ✅ DO use modern home-manager options (check version in flake.lock)

## File Update Protocol
**CRITICAL**: When making changes to this repository, you MUST:

1. **Always update CLAUDE.md** if you:
   - Add/remove hosts or users
   - Change key flake inputs or pin versions
   - Add new modules or major features
   - Modify the repository structure
   - Discover new conventions or patterns that should be documented

2. **Update relevant docs/** if you:
   - Change keybindings (update KEYBINDINGS.md)
   - Modify Neovim setup (update NEOVIM.md)
   - Change secrets management (update SECRETS.md)
   - Alter server infrastructure (update SERVER.md)
   - Add macOS-specific changes (update MACOS.md)
   - Add new features (update FEATURES.md)

3. **Update README.md** for:
   - Major architectural changes
   - New platform support
   - Breaking changes to deployment

**Example workflow:**
- Adding a new module? → Update CLAUDE.md with module description
- Changing Hyprland keybinding? → Update KEYBINDINGS.md
- Adding a new flake input? → Update CLAUDE.md with version/purpose
- Both changes? → Update both files in the same commit

## Secrets Management
- Uses **sops-nix** with **Age encryption**
- Secrets encrypted at rest in git
- See `docs/SECRETS.md` for full details
- NEVER commit unencrypted secrets
- Keys stored outside repo (Bitwarden CLI integration)

## Commit Guidelines
- **Never add Claude co-authoring** to commit messages
- **No "Co-Authored-By: Claude" lines** in commits
- **No "Generated with Claude Code" references** in commit messages
- All commits should show only Daniel as the author
- Write concise, descriptive commit messages
- Follow conventional commits style when appropriate

## Context7 Integration
**Q: Should we use Context7 for this repo?**

Context7 could be beneficial for:
- ✅ **Module dependencies**: Track which modules import which
- ✅ **Option definitions**: Find where NixOS/home-manager options are set
- ✅ **Flake input usage**: See where each input is actually used
- ✅ **Cross-platform patterns**: Track how same functionality differs on Linux vs macOS

However, **CLAUDE.md is already serving a similar purpose** by providing:
- Repository structure and conventions
- Version information and deprecation warnings
- File update protocols

**Recommendation**: Context7 would be most useful if:
1. The repo grows significantly larger (more hosts, more users)
2. You want automated dependency tracking between modules
3. You're collaborating with others who need to understand module relationships

For a **personal config with 3 hosts**, CLAUDE.md is likely sufficient. Consider Context7 if you scale beyond ~5 hosts or add multiple users.

## Additional Notes
- This config is **production-tested** across all 3 machines
- All changes should be tested with `just flake-check` before building
- Hyprland config is in `modules/home-manager/desktop/hyprland/`
- Neovim config is heavily customized (see `docs/NEOVIM.md`)
- Server deployment is automated (see `docs/SERVER.md`)
- **swwwitch** is a custom Go-based wallpaper switcher for swww, maintained in a separate repo at `github.com/Danielbook/swwwitch`

## Quick Reference
- **Primary user**: daniel
- **Primary workstation**: weepinbell (NixOS + Hyprland)
- **Laptop**: coruscant (macOS + nix-darwin)
- **Server**: kamino (Home Assistant + monitoring)
- **Theme**: Catppuccin (everywhere)
- **Shell**: zsh with starship prompt
- **Editor**: Neovim (with Copilot, LSP, Treesitter)
- **Terminal**: Ghostty (Linux) / default (macOS)
- **Wallpaper switcher**: swwwitch (custom Go CLI for swww)