# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Declarative, flake-based Nix configuration for 4 hosts, 1 user (daniel). Uses nixos-unstable, modern flakes syntax only (no channels, no `nix-env`).

| Host | Platform | Purpose |
|------|----------|---------|
| `weepinbell` | NixOS + Hyprland | Primary workstation |
| `coruscant` | macOS + nix-darwin | MacBook Pro |
| `kamino` | NixOS headless | Home automation server |
| `tatooine` | NixOS headless | Media server |

## Build Commands

**Always use `just` targets, never raw `nixos-rebuild` or `home-manager` commands:**

```bash
just nixos-rebuild          # NixOS system rebuild
just home-manager-switch    # Home Manager switch
just darwin-rebuild         # macOS rebuild
just flake-check            # Validate before building
just flake-update           # Update all flake inputs
just nix-gc                 # Garbage collection
just deploy-kamino          # Server deploy via nixos-anywhere
just deploy-tatooine        # Media server deploy
just noctalia-sync          # Sync Noctalia UI changes to repo
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
- **Server infra** → `docs/SERVER.md`
- **macOS** → `docs/MACOS.md`
- **Features** → `docs/FEATURES.md`
- **Module patterns** → `docs/ARCHITECTURE.md`
