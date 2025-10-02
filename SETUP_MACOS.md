# macOS Setup with nix-darwin

This guide will walk you through setting up your 2017 MacBook Pro with nix-darwin and Home Manager.

## Prerequisites

1. **macOS Requirements**: Ensure you're running macOS 10.15 (Catalina) or later
2. **Xcode Command Line Tools**: Install if not already present:
   ```bash
   xcode-select --install
   ```
3. **Git**: Should be available after installing Xcode Command Line Tools

## Setup Process

### Method 1: Automated Bootstrap (Recommended)

1. **Clone this repository**:
   ```bash
   git clone https://github.com/Danielbook/nixos-config.git
   cd nixos-config
   ```

2. **Set your hostname** (if different from `coruscant`):
   ```bash
   sudo scutil --set HostName coruscant
   sudo scutil --set LocalHostName coruscant
   sudo scutil --set ComputerName "Coruscant"
   ```

3. **Run the bootstrap script**:
   ```bash
   make bootstrap-mac
   ```

4. **Restart your terminal** and verify installation:
   ```bash
   darwin-rebuild --version
   home-manager --version
   ```

### Method 2: Manual Setup

1. **Install Nix**:
   ```bash
   curl -L https://nixos.org/nix/install | sh -s -- --daemon
   ```

2. **Source Nix profile**:
   ```bash
   . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
   ```

3. **Clone this repository**:
   ```bash
   git clone https://github.com/Danielbook/nixos-config.git
   cd nixos-config
   ```

4. **Install nix-darwin**:
   ```bash
   make install-nix-darwin
   ```

5. **Install Home Manager**:
   ```bash
   make home-manager-switch
   ```

## Daily Usage

### System Updates

- **Update system configuration**:
  ```bash
  make darwin-rebuild
  ```

- **Update Home Manager configuration**:
  ```bash
  make home-manager-switch
  ```

- **Update flake inputs**:
  ```bash
  make flake-update
  ```

### Package Management

- **System packages**: Add to `modules/darwin/common/default.nix` or `modules/darwin/desktop/default.nix`
- **User packages**: Add to `home/daniel/coruscant/default.nix`
- **Homebrew packages**: Add to `hosts/coruscant/default.nix` in the homebrew section

## Configuration Structure

```
├── hosts/coruscant/            # MacBook Pro specific configuration
├── modules/darwin/             # Darwin-specific modules
│   ├── common/                 # Base system configuration
│   └── desktop/                # Desktop environment configuration
├── home/daniel/coruscant/      # Home Manager configuration for macOS
└── Makefile                    # Build commands
```

## Installed Applications

### Via Nix
- Development tools (git, neovim, tmux, etc.)
- Terminal utilities (jq, curl, wget, etc.)
- Programming languages and tools

### Via Homebrew
- Raycast (Spotlight replacement)
- 1Password (Password manager)
- Spotify (Music streaming)
- Discord (Communication)
- Obsidian (Note taking)
- Visual Studio Code (Code editor)
- iTerm2 (Terminal emulator)
- Firefox (Web browser)

### Via Mac App Store
- Xcode (Developer tools)

## System Preferences

The configuration automatically sets up:
- **Dock**: Auto-hide enabled, no recent apps, 48px tile size
- **Finder**: Show all extensions, path bar, and status bar
- **Trackpad**: Tap to click, three-finger drag
- **Keyboard**: Caps Lock → Escape mapping
- **Security**: Touch ID for sudo
- **Interface**: Dark mode enabled
- **Screenshots**: Saved to Desktop as PNG

## Troubleshooting

### Common Issues

1. **"command not found" after installation**:
   - Restart your terminal or source the nix profile:
     ```bash
     . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
     ```

2. **Permission denied errors**:
   - Ensure you have admin privileges and try again
   - Some operations may require `sudo`

3. **Homebrew conflicts**:
   - If you have existing Homebrew, consider backing up your Brewfile
   - nix-darwin will manage Homebrew declaratively

4. **Build failures**:
   - Check if your hostname matches the configuration (`coruscant`)
   - Verify macOS version compatibility
   - Try updating flake inputs: `make flake-update`

### Getting Help

- Check the [nix-darwin documentation](https://github.com/nix-darwin/nix-darwin)
- Review [Home Manager options](https://nix-community.github.io/home-manager/options.html)
- Consult the [Nix manual](https://nixos.org/manual/nix/stable/)

## Customization

### Adding New Applications

1. **Nix packages**: Add to the appropriate `home.packages` or `environment.systemPackages`
2. **Homebrew casks**: Add to `hosts/coruscant/default.nix` in the `homebrew.casks` section
3. **Mac App Store apps**: Add to `hosts/coruscant/default.nix` in the `homebrew.masApps` section

### Modifying System Preferences

Edit `hosts/coruscant/default.nix` and modify the `system.defaults` section. See the [nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html) for all available settings.

### Environment Variables and Shell Configuration

Modify `home/daniel/coruscant/default.nix` to add shell configurations, environment variables, and user-specific settings.