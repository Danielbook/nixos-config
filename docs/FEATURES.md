# ✨ Features

This document details all features available across different platforms.

## 🐧 Linux (NixOS) Features

### Desktop Environment
- **🪟 Hyprland**: Modern Wayland compositor with smooth animations and extensive customization
- **🎨 HyprPanel**: Feature-rich status bar with floating pills design
  - Built-in notification center (replaces separate notification daemons)
  - Dashboard with quick settings and media controls
  - System monitoring (CPU, RAM, battery, temperature)
  - Network, Bluetooth, and volume controls
  - Auto-detected NixOS icon
- **🔒 Hyprlock**: Secure screen locking with custom styling
- **💤 Hypridle**: Automatic screen dimming and locking
- **🖼️ Kanshi**: Dynamic display configuration

### Graphics & Hardware
- **🔧 NVIDIA Prime**: Hybrid graphics with proper offloading support
- **⚡ TLP**: Advanced power management for laptops
- **💡 Brightness Control**: Keyboard shortcuts for screen and keyboard backlight

### Screenshot & Media
- **📸 Hyprshot**: Flexible screenshot tool with region and window capture
- **🎨 Satty**: Modern screenshot annotation tool
- **🎥 Screen Recording**: Integrated recording functionality
- **👁️ OCR Support**: Text recognition from images with wl-ocr

### Tools & Utilities
- **📋 Cliphist**: Clipboard history manager
- **🎨 Hyprpicker**: Color picker tool
- **🖼️ SWWW**: Wayland wallpaper daemon with smooth transitions
- **🌅 Wlsunset**: Automatic screen temperature adjustment

## 🍎 macOS (Darwin) Features

### Window Management
- **🏗️ AeroSpace**: Tiling window manager with vim-style navigation
- **📐 Smart Layouts**: Automatic window arrangement with workspaces

### System Integration
- **⚙️ System Defaults**: Automated macOS preferences
  - Dock configuration (auto-hide, tile size)
  - Finder enhancements (extensions, path bar)
  - Trackpad settings (tap to click, three-finger drag)
  - Keyboard configuration (Caps Lock → Escape)
- **🔐 TouchID Integration**: TouchID for sudo authentication
- **🍺 Homebrew Management**: Declarative GUI application installation

### Applications (via Homebrew)
- **🚀 Raycast**: Enhanced Spotlight replacement
- **🎵 Spotify**: Music streaming
- **💬 Discord**: Communication
- **📝 Obsidian**: Note taking
- **💻 Visual Studio Code**: Code editor

## 🌐 Cross-Platform Features

### Terminal & Shell
- **👻 Ghostty**: Modern terminal emulator with:
  - Crisp font rendering with JetBrains Mono Nerd Font
  - Transparent background (80% opacity)
  - Automatic tmux session management
  - Catppuccin Macchiato theme
- **📟 Tmux**: Terminal multiplexer with:
  - Vim-aware pane navigation
  - Custom status bar
  - Project selector integration
- **⭐ Starship**: Beautiful cross-shell prompt with git integration
- **🐚 Zsh**: Enhanced shell with oh-my-zsh framework

### Development Tools
- **📝 Neovim**: Highly customized text editor with:
  - LSP support for multiple languages
  - Treesitter syntax highlighting
  - Telescope fuzzy finder
  - Neo-tree file explorer
  - Catppuccin theme
  - Extensive keybindings
- **🔧 Git**: Version control with delta pager
- **📦 Development Languages**: Node.js, Python, Go, Rust support

### Navigation & Productivity
- **📂 Zoxide**: Smart directory jumping with frequency tracking
- **🔍 Fzf**: Fuzzy finder for commands and files
- **🦇 Bat**: Enhanced cat with syntax highlighting
- **📊 Btop**: Beautiful system resource monitor
- **🌳 Eza**: Modern ls replacement with icons
- **🔎 Ripgrep**: Fast text search tool

### File Management
- **📁 Yazi**: Modern terminal file manager
- **📦 Compression**: Built-in support for zip, unzip, tar

### Password Management
- **🔐 Bitwarden**: Password manager with CLI integration
- **🔑 SSH Keys**: Bitwarden SSH agent support

### Theme
- **🎨 Catppuccin Macchiato**: Consistent dark theme across:
  - Terminal (Ghostty)
  - Editor (Neovim)
  - Shell (Starship prompt)
  - Desktop (Hyprland)
  - Status bar (HyprPanel)

## 🔐 Security Features

- **🛡️ Encrypted Secrets**: sops-nix with Age encryption
- **🔒 SSH Hardening**: Secure server configurations
- **🔥 Host Firewalls**: Restrictive firewall rules
- **📱 2FA Support**: Multi-factor authentication integration

## 📦 Package Management

- **❄️ Nix Flakes**: Reproducible package management
- **🏠 Home Manager**: User environment configuration
- **📦 Flatpak** (Linux): Sandboxed application support
- **🍺 Homebrew** (macOS): GUI application management

## 🚀 Performance

- **⚡ Fast Boot**: Optimized systemd services
- **💾 Automatic Cleanup**: Nix garbage collection
- **🔄 Rollback Support**: Easy system recovery
- **📊 Resource Efficient**: Minimal background processes
