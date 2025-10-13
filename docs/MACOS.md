# 🍎 macOS (Darwin) Setup

This configuration supports macOS through nix-darwin, providing declarative system management for your MacBook Pro.

## Prerequisites

1. **macOS Requirements**: Ensure you're running macOS 10.15 (Catalina) or later
2. **Xcode Command Line Tools**: Install if not already present:
   ```bash
   xcode-select --install
   ```
3. **Admin Privileges**: Ensure you have administrator access

## 🚀 Quick Bootstrap (Recommended)

### 1. Clone the Repository

```bash
git clone https://github.com/Danielbook/nixos-config.git
cd nixos-config
```

### 2. Set Hostname (Optional)

If different from `coruscant`:

```bash
sudo scutil --set HostName coruscant
sudo scutil --set LocalHostName coruscant
sudo scutil --set ComputerName "Coruscant"
```

### 3. Run Automated Bootstrap

```bash
just bootstrap-mac
```

This will:
- Install Nix package manager
- Install nix-darwin
- Install Home Manager
- Configure system preferences
- Install applications

### 4. Verify Installation

Restart your terminal and verify:

```bash
darwin-rebuild --version
home-manager --version
```

## 🛠️ Manual Setup

If you prefer manual installation or encounter issues with the bootstrap:

### 1. Install Nix

```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

### 2. Source Nix Profile

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Or restart your terminal.

### 3. Install nix-darwin

```bash
just install-nix-darwin
```

### 4. Install Home Manager

```bash
just home-manager-switch
```

## 📱 Daily Usage

### Update System Configuration

```bash
just darwin-rebuild
```

### Update User Environment

```bash
just home-manager-switch
```

### Update All Packages

```bash
just flake-update
```

### Rebuild Everything

```bash
just flake-update
just darwin-rebuild
just home-manager-switch
```

## 📁 Configuration Structure

```
├── hosts/coruscant/            # MacBook Pro system configuration
├── modules/darwin/             # Darwin-specific modules
│   ├── common/                 # Base macOS system settings
│   └── desktop/                # Desktop environment setup
├── home/daniel/coruscant/      # Home Manager configuration
└── modules/home-manager/       # Cross-platform user configurations
```

## 🍺 Installed Applications

### Via Nix

Cross-platform development tools and utilities:
- Git, Neovim, Tmux
- Ghostty terminal
- Programming languages (Node.js, Python, Go, Rust)
- Shell tools (zoxide, fzf, ripgrep, bat, eza)

### Via Homebrew

macOS-specific GUI applications:
- **🚀 Raycast**: Enhanced Spotlight replacement
- **🎵 Spotify**: Music streaming
- **💬 Discord**: Communication platform
- **📝 Obsidian**: Note-taking application
- **💻 Visual Studio Code**: Code editor

## ⚙️ Automated System Preferences

The configuration automatically configures macOS system preferences:

### Dock Settings
- Auto-hide enabled
- No recent applications
- Optimal tile size
- Bottom positioning

### Finder Preferences
- Show all file extensions
- Show path bar
- Show status bar
- Search current folder by default
- No warning when changing extensions

### Trackpad Configuration
- Tap to click enabled
- Three-finger drag enabled
- Natural scrolling

### Keyboard Settings
- Caps Lock → Escape mapping
- Fast key repeat
- Short initial key repeat delay

### Security
- TouchID for sudo authentication
- FileVault encryption (recommended)

### Interface
- Dark mode enabled
- Reduced motion
- Auto-hide menu bar

### Screenshots
- Saved to Desktop
- PNG format
- No shadow in window captures

## 🪟 AeroSpace Window Management

AeroSpace provides tiling window management with vim-style navigation.

### Basic Navigation
| Shortcut | Action |
|----------|--------|
| `Alt + Shift + Enter` | Open terminal |
| `Alt + h/j/k/l` | Navigate windows (vim-style) |
| `Alt + Shift + h/j/k/l` | Move windows |

### Workspace Management
| Shortcut | Action |
|----------|--------|
| `Alt + 1-9` | Switch to workspace 1-9 |
| `Alt + Shift + 1-9` | Move window to workspace 1-9 |

### Layout Control
| Shortcut | Action |
|----------|--------|
| `Alt + f` | Toggle fullscreen |
| `Alt + Shift + Space` | Toggle floating |
| `Alt + s` | Split horizontally |
| `Alt + v` | Split vertically |
| `Alt + r` | Reload configuration |

See [KEYBINDINGS.md](./KEYBINDINGS.md) for complete shortcuts.

## 🔧 Troubleshooting

### "command not found" after installation

**Solution**: Restart terminal or source nix profile:
```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Permission denied errors

**Solution**: Ensure you have administrator access and use `sudo` for system operations:
```bash
sudo just darwin-rebuild
```

### Build failures

**Possible causes:**
1. Hostname doesn't match configuration
2. macOS version incompatibility
3. Xcode Command Line Tools not installed

**Solutions:**
```bash
# Check hostname
hostname
scutil --get HostName

# Verify Xcode CLI tools
xcode-select -p

# Reinstall if needed
xcode-select --install
```

### Homebrew cask installation fails

**Solution**: Accept Xcode license:
```bash
sudo xcodebuild -license accept
```

### nix-darwin activation fails

**Solution**: Check for conflicting configurations:
```bash
# Remove old nix-darwin if exists
sudo rm -rf /etc/nix/nix.conf.before-nix-darwin

# Retry installation
just install-nix-darwin
```

## 🎨 Customization

### Adding System Packages

Edit `modules/darwin/common/default.nix`:

```nix
environment.systemPackages = with pkgs; [
  # Add your packages here
  htop
  wget
];
```

### Adding User Packages

Edit `home/daniel/coruscant/default.nix`:

```nix
home.packages = with pkgs; [
  # Add your packages here
  ripgrep
  fd
];
```

### Adding Homebrew Apps

Edit `hosts/coruscant/default.nix`:

```nix
homebrew.casks = [
  # Add GUI applications here
  "iterm2"
  "docker"
];
```

### Modifying System Preferences

Edit `modules/darwin/common/default.nix`:

```nix
system.defaults = {
  dock = {
    autohide = true;
    tilesize = 48;
  };
  finder = {
    AppleShowAllExtensions = true;
  };
};
```

## 🔄 Migration from Intel to Apple Silicon

### Export Configuration

On Intel Mac:
```bash
# Create backup of important data
tar czf ~/nix-config-backup.tar.gz ~/.config ~/Documents/code
```

### Import Configuration

On Apple Silicon Mac:
```bash
# Clone repository
git clone https://github.com/Danielbook/nixos-config.git
cd nixos-config

# Bootstrap
just bootstrap-mac

# Restore personal data
tar xzf ~/nix-config-backup.tar.gz -C ~
```

### Platform-Specific Considerations

The configuration automatically handles architecture differences:
- Native Apple Silicon packages when available
- Rosetta 2 fallback for Intel-only packages
- Optimized build flags for M1/M2/M3 chips

## 📚 Additional Resources

- [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [AeroSpace Documentation](https://github.com/nikitabobko/AeroSpace)
- [Nix Package Search](https://search.nixos.org/)

## 🎯 Quick Reference

```bash
# Bootstrap new Mac
just bootstrap-mac

# Update system
just darwin-rebuild

# Update packages
just home-manager-switch

# Update everything
just flake-update && just darwin-rebuild && just home-manager-switch

# Clean up old generations
just nix-gc

# Check configuration
just flake-check

# List all Just commands
just --list
```
