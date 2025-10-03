# Variables (override these as needed)
HOSTNAME ?= $(shell hostname)
FLAKE ?= .#$(HOSTNAME)
HOME_TARGET ?= $(FLAKE)
EXPERIMENTAL ?= --extra-experimental-features "nix-command flakes"

.PHONY: help install-nix install-nix-darwin darwin-rebuild nixos-rebuild \
	home-manager-switch nix-gc flake-update flake-check bootstrap-mac \
	deploy-dagobah deploy-tatooine deploy-hoth

help:
	@echo "Available targets:"
	@echo "  install-nix          - Install the Nix package manager"
	@echo "  install-nix-darwin   - Install nix-darwin (macOS only)"
	@echo "  darwin-rebuild       - Rebuild the Darwin configuration (macOS only)"
	@echo "  nixos-rebuild        - Rebuild the NixOS configuration"
	@echo "  home-manager-switch  - Switch the Home Manager configuration using flake $(HOME_TARGET)"
	@echo "  bootstrap-mac        - Bootstrap a fresh macOS system"
	@echo "  nix-gc               - Run Nix garbage collection"
	@echo "  flake-update         - Update flake inputs"
	@echo "  flake-check          - Check the flake for issues"
	@echo ""
	@echo "Server deployment targets:"
	@echo "  deploy-dagobah       - Deploy Dagobah server (home automation/monitoring)"
	@echo "  deploy-tatooine      - Deploy Tatooine server (coming soon)"
	@echo "  deploy-hoth          - Deploy Hoth server (coming soon)"

install-nix:
	@echo "Installing Nix..."
	@sudo curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
	@echo "Nix installation complete."

install-nix-darwin:
	@echo "Installing nix-darwin..."
	@nix $(EXPERIMENTAL) run nix-darwin -- switch --flake .#$(HOSTNAME)
	@echo "nix-darwin installation complete."

darwin-rebuild:
	@echo "Rebuilding Darwin configuration..."
	@darwin-rebuild switch --flake .#$(HOSTNAME)
	@echo "Darwin rebuild complete."

nixos-rebuild:
	@echo "Rebuilding NixOS configuration..."
	@sudo nixos-rebuild switch --flake $(FLAKE)
	@echo "NixOS rebuild complete."

home-manager-switch:
	@echo "Switching Home Manager configuration..."
	@home-manager $(EXPERIMENTAL) switch --flake $(HOME_TARGET)
	@echo "Home Manager switch complete."

nix-gc:
	@echo "Collecting Nix garbage..."
	@nix-collect-garbage -d
	@echo "Garbage collection complete."

flake-update:
	@echo "Updating flake inputs..."
	@nix $(EXPERIMENTAL) flake update
	@echo "Flake update complete."

flake-check:
	@echo "Checking flake..."
	@nix $(EXPERIMENTAL) flake check
	@echo "Flake check complete."

# Server deployment targets
deploy-dagobah:
	@echo "Deploying Dagobah server..."
	@read -p "Enter target IP address: " target_ip && \
	nixos-anywhere --flake .#dagobah nixos@$$target_ip
	@echo "Dagobah deployment complete."

deploy-tatooine:
	@echo "Tatooine server deployment not yet implemented"
	@echo "Coming soon..."

deploy-hoth:
	@echo "Hoth server deployment not yet implemented"
	@echo "Coming soon..."

bootstrap-mac:
	@echo "Bootstrapping macOS system..."
	@echo "1. Installing Nix..."
	@curl -L https://nixos.org/nix/install | sh -s -- --daemon
	@echo "2. Sourcing Nix profile..."
	@. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
	@echo "3. Installing nix-darwin..."
	@nix $(EXPERIMENTAL) run nix-darwin -- switch --flake .#$(HOSTNAME)
	@echo "4. Installing Home Manager..."
	@nix $(EXPERIMENTAL) run home-manager/master -- switch --flake .#daniel@$(HOSTNAME)
	@echo "Bootstrap complete! Please restart your terminal."
