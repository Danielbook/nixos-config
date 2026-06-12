# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Declarative, flake-based Nix configuration with a dendritic (multi-host-ready) architecture. 2 hosts, 1 user (daniel). Uses nixos-unstable, modern flakes syntax only (no channels, no `nix-env`).

| Host | Platform | Purpose |
|------|----------|---------|
| `coruscant` | NixOS + Hyprland | Primary workstation |
| `dagobah` | macOS (nix-darwin) | Apple Silicon MacBook Pro |

Modules are layered: `common` (universal for all hosts) and `desktop/common` (shared by desktop hosts). Adding a new host requires a host config, home config, and flake entry — servers skip desktop imports, desktops compose from the desktop layer.

## Build Commands

**Always use `just` targets, never raw `nixos-rebuild` or `home-manager` commands:**

```bash
just nixos-rebuild          # NixOS system rebuild (Linux)
just darwin-rebuild         # nix-darwin system rebuild (macOS)
just home-manager-switch    # Home Manager switch
just flake-check            # Validate before building
just flake-update           # Update all flake inputs
just nix-gc                 # Garbage collection
just noctalia-sync          # Sync Noctalia UI changes to repo
just format                 # Format Nix files (nixfmt-rfc-style)
just lint                   # Run statix + deadnix
just check-all              # Format + lint + flake check
```

## Architecture

See `docs/ARCHITECTURE.md` for detailed module patterns, specialArgs, and import conventions.

## Version Constraints

- **nixpkgs**: nixos-unstable — check `flake.lock` for exact rev
- **nix-flatpak**: Pinned to **v0.6.0**
- **stateVersion**: 25.05
- Prefer `pkgs.` prefix over `with pkgs;`

## Secrets

Uses **sops-nix** with **Age encryption**. Never commit unencrypted secrets. See `docs/SECRETS.md`.

## File Update Protocol

When making changes, update the relevant docs:
- **Hosts, flake inputs, structure** → This file
- **Keybindings** → `docs/KEYBINDINGS.md`
- **Neovim** → `docs/NEOVIM.md`
- **Secrets** → `docs/SECRETS.md`
- **Features** → `docs/FEATURES.md`
- **Module patterns** → `docs/ARCHITECTURE.md`
