# justfile - Modern task runner for NixOS configuration management
# Usage: just <recipe>
# List all recipes: just --list

# =============================================================================
# Variables
# =============================================================================

# Host configurations
kamino_host := "10.10.40.20"
tatooine_host := "10.10.40.104"  # Test VM (production: 10.10.40.11)
hoth_host := "10.10.40.12"

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
    @echo "  just darwin-rebuild          - Rebuild macOS configuration"
    @echo "  just home-manager-switch     - Switch Home Manager configuration"
    @echo ""
    @echo "🛠️  Development & Maintenance:"
    @echo "  just flake-update            - Update flake inputs"
    @echo "  just flake-check             - Check flake for issues"
    @echo "  just nix-gc                  - Run garbage collection"
    @echo ""
    @echo "🖥️  Server Deployment:"
    @echo "  just deploy-kamino           - Deploy Kamino (home automation)"
    @echo "  just deploy-tatooine         - Deploy Tatooine (media server)"
    @echo "  just deploy-hoth             - Deploy Hoth (coming soon)"
    @echo ""
    @echo "🔧 Setup & Utilities:"
    @echo "  just bootstrap-mac           - Bootstrap fresh macOS system"
    @echo "  just install-nix             - Install Nix package manager"
    @echo "  just check-bw                - Check Bitwarden CLI status"
    @echo "  just setup-kamino-secrets    - Set up Kamino secrets only"
    @echo "  just noctalia-sync           - Sync Noctalia UI changes to repo"
    @echo ""
    @echo "💡 Examples:"
    @echo "  just deploy-kamino           # Full Kamino deployment"
    @echo "  just check-bw                # Verify Bitwarden CLI setup"
    @echo "  just nixos-rebuild           # Rebuild local NixOS system"

# =============================================================================
# System Installation & Setup
# =============================================================================

# Install the Nix package manager
install-nix:
    @echo "📦 Installing Nix package manager..."
    @sudo curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
    @echo "✅ Nix installation complete."

# Install nix-darwin (macOS only)
install-nix-darwin:
    @echo "🍎 Installing nix-darwin..."
    @sudo -H nix {{experimental}} run nix-darwin -- switch --flake .#{{hostname}}
    @echo "✅ nix-darwin installation complete."

# Bootstrap a fresh macOS system with full setup
bootstrap-mac:
    @echo "🚀 Bootstrapping macOS system..."
    @echo "1️⃣  Installing Nix..."
    @curl -L https://nixos.org/nix/install | sh -s -- --daemon
    @echo "2️⃣  Sourcing Nix profile..."
    @. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    @echo "3️⃣  Installing nix-darwin..."
    @nix {{experimental}} run nix-darwin -- switch --flake .#{{hostname}}
    @echo "4️⃣  Installing Home Manager..."
    @nix {{experimental}} run home-manager/master -- switch --flake .#daniel@{{hostname}}
    @echo "🎉 Bootstrap complete! Please restart your terminal."

# =============================================================================
# Local System Management
# =============================================================================

# Rebuild the NixOS configuration
nixos-rebuild:
    @echo "🔄 Rebuilding NixOS configuration..."
    @sudo nixos-rebuild switch --flake {{flake}}
    @echo "✅ NixOS rebuild complete."

# Rebuild the Darwin configuration (macOS only)  
darwin-rebuild:
    @echo "🔄 Rebuilding Darwin configuration..."
    @sudo -H nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#{{hostname}}
    @echo "✅ Darwin rebuild complete."

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
# Server Deployment
# =============================================================================

# Deploy Kamino server (home automation/monitoring) with automated secrets
deploy-kamino:
    @echo "🚀 Deploying Kamino server..."
    @echo "📍 Target: {{kamino_host}}"
    @echo ""
    just _check-connectivity {{kamino_host}} "Kamino"
    @echo "🏗️  Starting NixOS deployment..."
    nixos-anywhere --flake .#kamino nixos@{{kamino_host}}
    @echo "✅ NixOS deployment complete"
    @echo ""
    @echo "🔑 Setting up secrets..."
    just setup-kamino-secrets
    @echo ""
    @echo "🎉 Kamino deployment complete!"
    @echo "💡 Verify with: ssh root@{{kamino_host}} 'docker ps'"
    @echo "🌐 Access services at: https://homeassistant.local.bookorjeman.com"

# Set up Age key for Kamino secrets with Bitwarden CLI integration and manual fallback
setup-kamino-secrets:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "🔑 Setting up Age key for sops-nix on Kamino..."
    
    # Check connectivity first
    if ! ping -c 1 {{kamino_host}} > /dev/null 2>&1; then
        echo "❌ Cannot reach {{kamino_host}}"
        echo "💡 Please ensure the server is accessible and try again"
        exit 1
    fi
    
    # Try Bitwarden CLI first
    if command -v bw >/dev/null 2>&1; then
        echo "🔐 Bitwarden CLI found, checking status..."
        
        if bw status | grep -q "unlocked"; then
            echo "✅ Bitwarden is unlocked, retrieving Age key..."
            
            # Try to get the key from Bitwarden
            age_key=$(bw get notes "Kamino sops-nix Age Keys" 2>/dev/null | grep "Private Key:" | cut -d: -f2 | xargs || echo "")
            
            if [ -n "$age_key" ] && [[ "$age_key" == AGE-SECRET-KEY-* ]]; then
                echo "✅ Age key retrieved from Bitwarden"
                echo "$age_key" | ssh root@{{kamino_host}} "mkdir -p /var/lib/sops-nix && cat > /var/lib/sops-nix/key.txt && chmod 600 /var/lib/sops-nix/key.txt"
                echo "✅ Age key deployed successfully via Bitwarden CLI"
                exit 0
            else
                echo "⚠️  Could not find valid Age key in Bitwarden note 'Kamino sops-nix Age Keys'"
                echo "💡 Falling back to manual entry..."
            fi
        else
            echo "🔒 Bitwarden is locked"
            echo "💡 You can unlock it with: bw unlock"
            echo "💡 Or continue with manual entry..."
        fi
    else
        echo "⚠️  Bitwarden CLI not found"
        echo "💡 Install with: brew install bitwarden-cli (macOS) or equivalent"
        echo "💡 Continuing with manual entry..."
    fi
    
    # Manual fallback
    echo ""
    echo "📋 Manual Age key entry:"
    echo "Please paste the Age private key from your Bitwarden note:"
    echo "(It should start with 'AGE-SECRET-KEY-')"
    echo ""
    echo -n "🔑 Age key: "
    read -s age_key
    echo ""
    
    # Validate the key format
    if [ -z "$age_key" ]; then
        echo "❌ No key provided"
        exit 1
    fi
    
    if [[ ! "$age_key" == AGE-SECRET-KEY-* ]]; then
        echo "❌ Invalid Age key format (should start with 'AGE-SECRET-KEY-')"
        exit 1
    fi
    
    # Deploy the key
    echo "🚀 Deploying Age key to server..."
    echo "$age_key" | ssh root@{{kamino_host}} "mkdir -p /var/lib/sops-nix && cat > /var/lib/sops-nix/key.txt && chmod 600 /var/lib/sops-nix/key.txt"
    echo "✅ Age key deployed successfully via manual entry"

# Deploy Tatooine server (media server with Jellyfin, Immich, n8n)
deploy-tatooine:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🏜️  Deploying Tatooine server..."
    echo "📍 Target: {{tatooine_host}}"
    echo ""
    just _check-connectivity {{tatooine_host}} "Tatooine"
    echo "🏗️  Starting NixOS deployment with nixos-anywhere..."
    echo "⚠️  This will WIPE the disk on {{tatooine_host}}!"
    echo "📦 Creating a test VM in Proxmox first is recommended"
    echo ""
    read -p "Continue with deployment? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Deployment cancelled"
        exit 1
    fi
    nixos-anywhere --flake .#tatooine nixos@{{tatooine_host}}
    echo "✅ NixOS deployment complete"
    echo ""
    echo "📦 Next steps:"
    echo "   Optional: Set up TrueNAS credentials with: just setup-tatooine-credentials"
    echo "   1. Copy docker-compose files from old system:"
    echo "      rsync -av daniel@<old-tatooine>:/srv/docker/ {{tatooine_host}}:/srv/docker/"
    echo "   2. Copy Immich .env file with database credentials"
    echo "   3. Restart docker services: ssh root@{{tatooine_host}} 'systemctl restart docker-compose-tatooine'"
    echo ""
    echo "🎉 Tatooine deployment complete!"
    echo "💡 Verify with: ssh root@{{tatooine_host}} 'docker ps'"
    echo "🌐 Jellyfin: http://{{tatooine_host}}:8096"
    echo "🌐 Immich: http://{{tatooine_host}}:2283"

# Set up TrueNAS CIFS credentials for Tatooine
setup-tatooine-credentials:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "🔑 Setting up TrueNAS CIFS credentials for Tatooine..."

    # Check connectivity first
    if ! ping -c 1 {{tatooine_host}} > /dev/null 2>&1; then
        echo "❌ Cannot reach {{tatooine_host}}"
        echo "💡 Please ensure the server is accessible and try again"
        exit 1
    fi

    echo "📋 Please provide TrueNAS CIFS credentials:"
    echo -n "Username (e.g., arr-data-smb): "
    read truenas_user
    echo -n "Password: "
    read -s truenas_pass
    echo ""

    # Create credentials file
    cat << EOF | ssh root@{{tatooine_host}} "cat > /etc/nixos/truenas-credentials && chmod 600 /etc/nixos/truenas-credentials"
    username=$truenas_user
    password=$truenas_pass
    EOF

    echo "✅ TrueNAS credentials deployed successfully"
    echo "💡 Testing CIFS mount..."
    ssh root@{{tatooine_host}} "systemctl restart mnt-truenas-data.mount" || echo "⚠️  Mount failed - you may need to troubleshoot manually"

# Deploy Hoth server (placeholder) 
deploy-hoth:
    @echo "❄️  Hoth server deployment not yet implemented"
    @echo "🚧 Coming soon..."
    @echo "📍 Planned target: {{hoth_host}}"

# =============================================================================
# Utilities & Diagnostics
# =============================================================================

# Sync Noctalia config changes back to the repo
noctalia-sync:
    @echo "🎨 Syncing Noctalia config to repo..."
    @cp ~/.config/noctalia/settings.json home/daniel/weepinbell/noctalia/
    @cp ~/.config/noctalia/user-templates.toml home/daniel/weepinbell/noctalia/
    @cp ~/.config/noctalia/plugins.json home/daniel/weepinbell/noctalia/
    @echo "✅ Noctalia config synced!"
    @echo "💡 Don't forget to commit the changes"

# Check Bitwarden CLI installation and status
check-bw:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "🔍 Checking Bitwarden CLI status..."
    echo ""
    
    if command -v bw >/dev/null 2>&1; then
        echo "✅ Bitwarden CLI found"
        echo "📋 Version: $(bw --version)"
        echo ""
        
        status=$(bw status | jq -r .status 2>/dev/null || echo "unknown")
        case "$status" in
            "unlocked")
                echo "✅ Bitwarden is unlocked and ready"
                echo "💡 You can use automated secret deployment"
                ;;
            "locked")
                echo "🔒 Bitwarden is locked"
                echo "💡 Unlock with: bw unlock"
                echo "💡 Then set: export BW_SESSION=\"<session-key>\""
                ;;
            "unauthenticated")
                echo "❌ Bitwarden is not authenticated"
                echo "💡 Login with: bw login"
                ;;
            *)
                echo "⚠️  Unknown Bitwarden status: $status"
                echo "💡 Try: bw status"
                ;;
        esac
        
        echo ""
        echo "🔍 Checking for Kamino secrets note..."
        if bw status | grep -q "unlocked"; then
            if bw get notes "Kamino sops-nix Age Keys" >/dev/null 2>&1; then
                echo "✅ Found 'Kamino sops-nix Age Keys' note in Bitwarden"
            else
                echo "❌ Could not find 'Kamino sops-nix Age Keys' note"
                echo "💡 Please ensure the note exists with the correct name"
            fi
        else
            echo "⚠️  Cannot check notes - Bitwarden is locked"
        fi
    else
        echo "❌ Bitwarden CLI not found"
        echo ""
        echo "📦 Installation options:"
        echo "  macOS:    brew install bitwarden-cli"
        echo "  Linux:    Download from https://bitwarden.com/download/"
        echo "  NixOS:    nix-shell -p bitwarden-cli"
        echo ""
        echo "💡 After installation, login with: bw login"
    fi

# =============================================================================
# Internal Helper Recipes
# =============================================================================

# Internal: Check connectivity to a host
_check-connectivity host name:
    @echo "🔗 Checking connectivity to {{name}} ({{host}})..."
    @ping -c 1 {{host}} > /dev/null || (echo "❌ Cannot reach {{host}}" && echo "💡 Please ensure {{name}} is accessible and try again" && exit 1)
    @echo "✅ {{name}} is reachable"

# Internal: Validate Age key format
_validate-age-key key:
    @if [[ ! "{{key}}" == AGE-SECRET-KEY-* ]]; then echo "❌ Invalid Age key format" && exit 1; fi
    @echo "✅ Age key format is valid"