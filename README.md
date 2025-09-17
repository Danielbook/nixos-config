# 🐧 Daniel's NixOS Configuration

> A declarative NixOS configuration with Hyprland, featuring a modern development environment and seamless desktop experience.

## 📁 Repository Structure

- 📦 `flake.nix`: Main flake configuration defining inputs and outputs for NixOS and Home Manager
- 🖥️ `hosts/`: Machine-specific NixOS configurations
  - 🐛 `weepinbell/`: Primary workstation configuration
- 🏠 `home/`: User-specific Home Manager configurations  
- 📄 `files/`: Miscellaneous assets (avatars, scripts, etc.)
- 🧩 `modules/`: Reusable configuration modules
  - ⚙️ `nixos/`: System-level NixOS modules
  - 👤 `home-manager/`: User-space application and service configurations
- 🔧 `overlays/`: Custom Nix package overlays
- 🔒 `flake.lock`: Reproducible build lock file

## 🔗 Key Dependencies

- 📦 **nixpkgs**: Latest packages from `nixos-unstable` channel
- 🛡️ **nixpkgs-stable**: Stable packages from `nixos-25.05` channel  
- 🏠 **home-manager**: Declarative user environment management
- 🖥️ **nixos-hardware**: Hardware-optimized NixOS configurations
- 🎨 **catppuccin**: Beautiful pastel theme system-wide
- 📱 **nix-flatpak**: Declarative Flatpak application management
- 🌊 **plasma-manager**: KDE Plasma configuration management

## ✨ Features

- 🪟 **Hyprland**: Modern Wayland compositor with smooth animations
- 🎨 **Catppuccin Theme**: Consistent dark theme across all applications  
- 🔧 **NVIDIA Prime**: Hybrid graphics with proper offloading support
- 📋 **SwayNC**: Beautiful notification center
- 🗃️ **Albert Launcher**: Fast application launcher
- 📊 **Waybar**: Customizable status bar
- 🔒 **Hyprlock**: Secure screen locking
- 📸 **Screenshot Tools**: Built-in region and fullscreen capture
- 🎥 **Screen Recording**: Integrated recording functionality
- 👁️ **OCR Support**: Text recognition from images

## ⌨️ Keyboard Shortcuts

**Main Modifier:** `Super` (Windows key)

### 🚀 Applications
| Shortcut | Action |
|----------|--------|
| `Super + Shift + Enter` | 🖥️ Open terminal (Ghostty) |
| `Super + Shift + F` | 📁 Open file manager (Nautilus) |
| `Super + A` | 🗃️ Show applications menu |
| `Ctrl + Space` | 🔍 Toggle Albert launcher |
| `Super + N` | 📋 Toggle notifications (SwayNC) |

### 🪟 Window Management  
| Shortcut | Action |
|----------|--------|
| `Super + Q` | ❌ Kill active window |
| `Ctrl + Alt + Q` | 🚪 Exit Hyprland |
| `Super + F` | 📌 Toggle floating mode |
| `Super + M` | 📺 Toggle fullscreen |
| `Super + Return` | 🔄 Swap with master window |
| `Super + O` | 🔄 Cycle layout orientation |

### 🧭 Navigation (Vim-style)
| Shortcut | Action |
|----------|--------|
| `Super + h/j/k/l` | 👆 Move focus (left/down/up/right) |
| `Super + Shift + ←→↑↓` | 📏 Resize window |
| `Super + 1-9,0` | 🏠 Switch to workspace 1-10 |
| `Super + Shift + 1-9,0` | 📦 Move window to workspace 1-10 |

### 📸 Screenshots & Tools
| Shortcut | Action |
|----------|--------|
| `Super + Shift + S` | 📷 Screenshot region |
| `Super + Ctrl + S` | 🖼️ Screenshot full screen |  
| `Super + Shift + R` | 🎥 Start screen recording |
| `Super + Shift + C` | 🎨 Color picker |
| `Alt + Shift + 2` | 👁️ OCR text recognition |

### 🎵 System Controls
| Shortcut | Action |
|----------|--------|
| `Volume Keys` | 🔊 Adjust system volume |
| `Brightness Keys` | 💡 Adjust screen brightness |
| `Shift + Brightness` | ⌨️ Adjust keyboard backlight |
| `Ctrl + Alt + L` | 🔒 Lock screen |

## 📝 Neovim Keybindings

**Leader Key:** `Space`

### 📁 File Management
| Shortcut | Action |
|----------|--------|
| `<leader>pv` | 📂 Open file explorer (netrw) |
| `<leader>ff` | 🔍 Find files (Telescope) |
| `<leader>fb` | 📄 Find buffers (Telescope) |
| `Ctrl + p` | 🗂️ Find git files (Telescope) |
| `<leader>gw` | 🔎 Live grep search (Telescope) |
| `<leader>fh` | ❓ Help tags (Telescope) |

### 🪟 Window Navigation
| Shortcut | Action |
|----------|--------|
| `Ctrl + h/j/k/l` | ↔️ Navigate between panes |
| `<leader>w` | 💾 Save file |
| `<leader>q` | 🚪 Quit |
| `Ctrl + n` | 🌳 Toggle Neo-tree (left) |
| `<leader>bf` | 📋 Show buffers (Neo-tree float) |

### 🔍 Search & Replace
| Shortcut | Action |
|----------|--------|
| `<leader>fw` | 🎯 Search word under cursor |
| `<leader>fW` | 🎯 Search WORD under cursor |
| `<leader>gd` | 🔗 Go to definition (LSP) |
| `<leader>gr` | 📚 Find references (LSP) |

### 📝 Text Editing
| Shortcut | Action |
|----------|--------|
| `<leader>p` | 📋 Paste without overwriting register |
| `<leader>y` | 📄 Yank to system clipboard |
| `<leader>Y` | 📄 Yank line to system clipboard |
| `Ctrl + d/u` | ⬇️⬆️ Half page down/up (centered) |
| `Ctrl + f/b` | 📃 Full page down/up (centered) |

### 🛠️ LSP & Development
| Shortcut | Action |
|----------|--------|
| `K` | 📖 Show hover documentation |
| `<leader>vws` | 🔍 Workspace symbol search |
| `<leader>vd` | ⚠️ Open diagnostic float |
| `<leader>ca` | ⚡ Code actions |
| `<leader>rn` | ✏️ Rename symbol |
| `Ctrl + h` | 📝 Signature help (insert mode) |
| `[d` / `]d` | ⬅️➡️ Navigate diagnostics |
| `<leader>bf` | 🎨 Format buffer |

### 📚 Utilities
| Shortcut | Action |
|----------|--------|
| `<leader>u` | 🌳 Toggle undo tree |
| `Ctrl + c` | 🔄 Escape (insert mode) |

## 📟 Tmux Keybindings

**Prefix Key:** `Ctrl + Q`

### 🪟 Window & Session Management
| Shortcut | Action |
|----------|--------|
| `Ctrl + Q` then `c` | ➕ Create new window |
| `Ctrl + Q` then `r` | ✏️ Rename current window |
| `Ctrl + Q` then `R` | 🔄 Reload tmux config |
| `Ctrl + Q` then `d` | 🚪 Detach from session |
| `Ctrl + Q` then `n` | ➡️ Next window |
| `Ctrl + Q` then `p` | ⬅️ Previous window |
| `Ctrl + Q` then `1-9` | 🔢 Switch to window number |

### 🔄 Pane Management
| Shortcut | Action |
|----------|--------|
| `Ctrl + Q` then `v` | ↔️ Split pane vertically |
| `Ctrl + Q` then `s` | ↕️ Split pane horizontally |
| `Ctrl + h/j/k/l` | 🧭 Navigate panes (vim-style) |
| `Shift + ←→↑↓` | 📏 Resize panes |
| `Ctrl + Q` then `x` | ❌ Close current pane |

### 🔧 Utilities
| Shortcut | Action |
|----------|--------|
| `Ctrl + Q` then `Ctrl + L` | 🧹 Clear screen |
| `Ctrl + F` | 📁 Open project selector |
| Mouse scroll | 📜 Scroll through history |

### 📋 Copy Mode (Vi-style)
| Shortcut | Action |
|----------|--------|
| `Ctrl + Q` then `[` | 📋 Enter copy mode |
| `Space` | 📍 Start selection (in copy mode) |
| `Enter` | 📄 Copy selection (in copy mode) |
| `Ctrl + Q` then `]` | 📥 Paste |

## 🚀 Quick Start

### Initial Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/nixos-config.git
cd nixos-config

# Build and switch (requires sudo)
sudo nixos-rebuild switch --flake .#weepinbell

# Apply Home Manager configuration  
home-manager switch --flake .#daniel@weepinbell
```

### 🔧 Adding a New Machine

1. **📝 Update `flake.nix`**:
   ```nix
   # Add to users configuration
   users = {
     daniel = { /* existing config */ };
     newuser = {
       avatar = ./files/avatar/face;
       email = "user@example.com";
       fullName = "New User";
       name = "newuser";
     };
   };
   
   # Add machine configurations
   nixosConfigurations = {
     weepinbell = mkNixosConfiguration "weepinbell" "daniel";
     newmachine = mkNixosConfiguration "newmachine" "newuser";
   };
   
   homeConfigurations = {
     "daniel@weepinbell" = mkHomeConfiguration "x86_64-linux" "daniel" "weepinbell";  
     "newuser@newmachine" = mkHomeConfiguration "x86_64-linux" "newuser" "newmachine";
   };
   ```

2. **🖥️ Create System Configuration**:
   ```bash
   mkdir -p hosts/newmachine
   sudo nixos-generate-config --show-hardware-config > hosts/newmachine/hardware-configuration.nix
   ```
   
   Create `hosts/newmachine/default.nix`:
   ```nix
   { hostname, nixosModules, ... }:
   {
     imports = [
       ./hardware-configuration.nix
       "${nixosModules}/common"
       "${nixosModules}/desktop/hyprland"
       "${nixosModules}/nvidia"  # If needed
     ];
     
     networking.hostName = hostname;
     system.stateVersion = "25.05";
   }
   ```

3. **🏠 Create Home Configuration**:
   ```bash
   mkdir -p home/newuser/newmachine
   ```
   
   Create `home/newuser/newmachine/default.nix`:
   ```nix
   { nhModules, ... }:
   {
     imports = [
       "${nhModules}/common"
       "${nhModules}/desktop/hyprland"
     ];
     
     home.stateVersion = "25.05";
   }
   ```

4. **🚀 Deploy**:
   ```bash
   git add .
   sudo nixos-rebuild switch --flake .#newmachine
   home-manager switch --flake .#newuser@newmachine
   ```

## 🛠️ Troubleshooting

### 🖤 Black Applications (GTK rendering issues)
If applications like pavucontrol or SwayNC appear black:
- ✅ **Fixed**: GTK Wayland environment variables are configured
- 🔄 **Solution**: Restart Hyprland after `nixos-rebuild switch`

### 🎮 NVIDIA Issues
- ✅ **Configured**: NVIDIA Prime offloading enabled
- 🔍 **Check GPUs**: `ls -la /sys/class/drm/` to verify graphics cards
- 🔧 **Bus IDs**: Update `intelBusId` and `nvidiaBusId` in `modules/nixos/nvidia/default.nix`

### 🏠 Home Manager Bootstrap
On fresh systems:
```bash
nix-shell -p home-manager
home-manager switch --flake .#daniel@weepinbell
```

### 🔄 Configuration Updates  
```bash
# System updates
sudo nixos-rebuild switch --flake .

# User environment updates  
home-manager switch --flake .
```

## 📚 Useful Commands

```bash
# Update flake inputs
nix flake update

# Check what will be built
nixos-rebuild dry-build --flake .

# Garbage collection
sudo nix-collect-garbage -d

# Show system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```
