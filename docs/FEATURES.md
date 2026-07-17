# Features

## Desktop Environment
- **Hyprland**: Modern Wayland compositor with smooth animations and extensive customization
- **Noctalia Shell**: Beautiful desktop shell built on Quickshell
  - Bar with workspaces, window title, system tray, and clock
  - Built-in notification center with history
  - Control center with quick settings
  - Integrated lock screen with PAM authentication
  - Media controls and system monitoring
  - Network, Bluetooth, and volume controls
- **Hypridle**: Automatic screen dimming and locking
- **Kanshi**: Dynamic display configuration

## Graphics & Hardware
- **NVIDIA Prime Sync**: Intel iGPU + NVIDIA dGPU on coruscant; HDMI routed through dGPU, open kernel modules
- **TLP**: Advanced power management for laptops
- **Brightness Control**: Keyboard shortcuts for screen and keyboard backlight

## Screenshot & Media
- **Hyprshot**: Flexible screenshot tool with region and window capture
- **Satty**: Modern screenshot annotation tool
- **Screen Recording**: Integrated recording functionality
- **OCR Support**: Text recognition from images with wl-ocr

## Tools & Utilities
- **Cliphist**: Clipboard history manager
- **Hyprpicker**: Color picker tool
- **Wlsunset**: Automatic screen temperature adjustment

## Terminal & Shell
- **Ghostty**: Modern terminal emulator with JetBrains Mono, transparent background, tmux integration
- **Tmux**: Terminal multiplexer with vim-aware navigation and custom status bar
- **Starship**: Beautiful cross-shell prompt with git integration
- **Zsh**: Enhanced shell with oh-my-zsh framework

## Development Tools
- **Neovim**: Highly customized editor with LSP, Treesitter, Telescope, Neo-tree, Catppuccin theme
- **Git**: Version control with delta pager
- **Development Languages**: Node.js, Python, Go, Rust support

## Navigation & Productivity
- **Zoxide**: Smart directory jumping with frequency tracking
- **Fzf**: Fuzzy finder for commands and files
- **Bat**: Enhanced cat with syntax highlighting
- **Btop**: Beautiful system resource monitor
- **Eza**: Modern ls replacement with icons
- **Ripgrep**: Fast text search tool

## File Management
- **Yazi**: Modern terminal file manager

## Password Management
- **Bitwarden**: Password manager with CLI integration
- **SSH Keys**: Bitwarden SSH agent support

## Theme
- **Catppuccin Macchiato**: Consistent dark theme across terminal, editor, shell, desktop, and status bar

## Security
- **Encrypted Secrets**: sops-nix with Age encryption
- **SSH Hardening**: Secure configurations
- **Host Firewall**: Restrictive firewall rules

## Package Management
- **Nix Flakes**: Reproducible package management
- **Home Manager**: User environment configuration
- **Flatpak**: Sandboxed application support

## Homelab Cluster
- **k3s HA cluster**: 3 control-planes (naboo/endor/hoth, embedded etcd) + GPU
  agent (tatooine, GTX 1070 time-sliced via NVIDIA device plugin)
- **GitOps**: Argo CD app-of-apps over `k8s/`, secrets via ksops + sops/Age
- **Storage**: democratic-csi against TrueNAS (iSCSI + NFS StorageClasses)
- See `docs/CLUSTER.md` (strategy), `docs/cluster-implementation.md` (history),
  `docs/improvements.md` (deferred work)
