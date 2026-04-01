# justfile - Modern task runner for Nix configuration management
# Usage: just <recipe>
# List all recipes: just --list

# =============================================================================
# Variables
# =============================================================================

# Flake configuration
hostname := `hostname`
flake := ".#" + hostname
home_target := ".#daniel@" + hostname
experimental := "--extra-experimental-features \"nix-command flakes\""

# =============================================================================
# Help and Information
# =============================================================================

# List all available recipes
default:
    @just --list

# Show detailed help with examples
help:
    @echo "🚀 NixOS Configuration Management with Just"
    @echo ""
    @echo "📋 Available commands:"
    @echo ""
    @echo "🏠 Local System Management:"
    @echo "  just nixos-rebuild           - Rebuild NixOS configuration"
    @echo "  just home-manager-switch     - Switch Home Manager configuration"
    @echo ""
    @echo "🛠️  Development & Maintenance:"
    @echo "  just flake-update            - Update flake inputs"
    @echo "  just flake-check             - Check flake for issues"
    @echo "  just nix-gc                  - Run garbage collection"
    @echo ""
    @echo "🔧 Utilities:"
    @echo "  just install-nix             - Install Nix package manager"
    @echo "  just noctalia-sync           - Sync Noctalia UI changes to repo"
    @echo ""
    @echo "💡 Examples:"
    @echo "  just nixos-rebuild           # Rebuild local NixOS system"
    @echo "  just home-manager-switch     # Switch Home Manager config"

# =============================================================================
# System Installation & Setup
# =============================================================================

# Install the Nix package manager
install-nix:
    @echo "📦 Installing Nix package manager..."
    @sudo curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
    @echo "✅ Nix installation complete."

# =============================================================================
# Local System Management
# =============================================================================

# Rebuild the NixOS configuration (Linux only)
nixos-rebuild:
    @echo "🔄 Rebuilding NixOS configuration..."
    @sudo nixos-rebuild switch --flake {{flake}}
    @echo "✅ NixOS rebuild complete."

# Rebuild the nix-darwin configuration (macOS only)
darwin-rebuild:
    @echo "🔄 Rebuilding nix-darwin configuration..."
    @darwin-rebuild switch --flake {{flake}}
    @echo "✅ nix-darwin rebuild complete."

# Switch the Home Manager configuration
home-manager-switch:
    @echo "🏠 Switching Home Manager configuration..."
    @just noctalia-sync || true
    @home-manager {{experimental}} switch --flake {{home_target}}
    @echo "✅ Home Manager switch complete."

# =============================================================================
# Development & Maintenance
# =============================================================================

# Update flake inputs to latest versions
flake-update:
    @echo "📡 Updating flake inputs..."
    @nix {{experimental}} flake update
    @echo "✅ Flake update complete."

# Check the flake configuration for issues
flake-check:
    @echo "🔍 Checking flake configuration..."
    @nix {{experimental}} flake check
    @echo "✅ Flake check complete."

# Run Nix garbage collection to free up space
nix-gc:
    @echo "🗑️  Collecting Nix garbage..."
    @nix-collect-garbage -d
    @echo "✅ Garbage collection complete."

# =============================================================================
# Code Quality
# =============================================================================

# Format all Nix files
format:
    @nix fmt

# Check formatting without modifying
format-check:
    @nix fmt -- --check .

# Run linters (statix + deadnix)
lint:
    @nix run nixpkgs#deadnix -- --fail .
    @nix run nixpkgs#statix -- check .

# Run all checks
check-all: format-check lint flake-check

# =============================================================================
# Utilities
# =============================================================================

# Sync Noctalia config changes back to the repo
noctalia-sync:
    #!/usr/bin/env bash
    set -euo pipefail
    src="$HOME/.config/noctalia"
    dest="home/daniel/coruscant/noctalia"
    if [ ! -d "$src" ]; then
        echo "⚠️  Noctalia config dir not found at $src, skipping sync"
        exit 0
    fi
    changed=0
    for file in settings.json user-templates.toml plugins.json; do
        if [ -f "$src/$file" ]; then
            if ! diff -q "$src/$file" "$dest/$file" >/dev/null 2>&1; then
                cp "$src/$file" "$dest/$file"
                echo "  Updated $file"
                changed=1
            fi
        fi
    done
    if [ "$changed" -eq 0 ]; then
        echo "🎨 Noctalia config already in sync"
    else
        echo "🎨 Noctalia config synced!"
    fi
