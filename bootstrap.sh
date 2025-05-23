#!/usr/bin/env bash
set -e

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔗 Copying configuration files to /etc/nixos..."
sudo cp -rv "$CONFIG_DIR"/* /etc/nixos/

echo "🔄 Rebuilding system from new configuration..."
sudo nixos-rebuild switch

echo "✅ NixOS has been configured and switched!"

