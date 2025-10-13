# ⌨️ Keyboard Shortcuts

Comprehensive keybinding reference for all tools in this configuration.

## 🪟 Hyprland (Window Manager)

**Main Modifier:** `Super` (Windows key)

### 🚀 Applications
| Shortcut | Action |
|----------|--------|
| `Super + Shift + Enter` | 🖥️ Open terminal (Ghostty) |
| `Super + Shift + F` | 📁 Open file manager (Nautilus) |
| `Super + A` | 🗃️ Show applications menu (Fuzzel) |
| `Super + N` | 📋 Toggle notification center (HyprPanel) |
| `Super + /` | 🔑 Show shortcuts viewer |

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
| `Super + Mouse scroll` | 🔄 Switch workspaces |
| `Super + Space` | 🌐 Switch keyboard layout (US/SE) |

### 📸 Screenshots & Tools
| Shortcut | Action |
|----------|--------|
| `Super + Shift + S` | 📷 Screenshot region (with Satty annotation) |
| `Super + Ctrl + S` | 🖼️ Screenshot window (with Satty annotation) |
| `Super + Shift + R` | 🎥 Start screen recording |
| `Super + Shift + C` | 🎨 Color picker (Hyprpicker) |
| `Alt + Shift + 2` | 👁️ OCR text recognition |

### 🎵 System Controls
| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | 🔊 Increase volume |
| `XF86AudioLowerVolume` | 🔉 Decrease volume |
| `XF86AudioMute` | 🔇 Toggle mute |
| `XF86AudioMicMute` | 🎤 Toggle microphone mute |
| `XF86MonBrightnessUp` | 💡 Increase brightness |
| `XF86MonBrightnessDown` | 🌑 Decrease brightness |
| `Shift + XF86MonBrightnessUp` | ⌨️ Increase keyboard backlight |
| `Shift + XF86MonBrightnessDown` | ⌨️ Decrease keyboard backlight |
| `Ctrl + Alt + L` | 🔒 Lock screen (Hyprlock) |

## 📝 Neovim

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

### 🪟 Window & Buffer Management
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
| `J` | 🔗 Join lines (keeps cursor position) |

### 🎯 Treesitter Text Objects
| Shortcut | Action |
|----------|--------|
| `af` | 📦 Select around function |
| `if` | 📦 Select inside function |
| `ac` | 📦 Select around class |
| `ic` | 📦 Select inside class |
| `aa` | 📦 Select around parameter |
| `ia` | 📦 Select inside parameter |

### 🧭 Treesitter Navigation
| Shortcut | Action |
|----------|--------|
| `]f` | ➡️ Next function start |
| `]F` | ➡️ Next function end |
| `]c` | ➡️ Next class start |
| `]C` | ➡️ Next class end |
| `[f` | ⬅️ Previous function start |
| `[F` | ⬅️ Previous function end |
| `[c` | ⬅️ Previous class start |
| `[C` | ⬅️ Previous class end |

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

### 🎨 Font Size (Ghostty Terminal)
| Shortcut | Action |
|----------|--------|
| `Ctrl + Shift + =` | ➕ Increase font size |
| `Ctrl + -` | ➖ Decrease font size |
| `Ctrl + 0` | 🔄 Reset font size |

## 📟 Tmux

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
| `Ctrl + h/j/k/l` | 🧭 Navigate panes (vim-aware) |
| `Shift + ←→↑↓` | 📏 Resize panes |
| `Ctrl + Q` then `x` | ❌ Close current pane |
| `Ctrl + Q` then `z` | 🔍 Zoom/unzoom pane |

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
| `v` | 📍 Visual select (in copy mode) |
| `y` | 📄 Yank selection (in copy mode) |

## 🍎 AeroSpace (macOS)

**Main Modifier:** `Alt`

### 🪟 Window Management
| Shortcut | Action |
|----------|--------|
| `Alt + Shift + Enter` | 🖥️ Open terminal |
| `Alt + h/j/k/l` | 👆 Navigate windows (vim-style) |
| `Alt + Shift + h/j/k/l` | 📦 Move windows |
| `Alt + f` | 📺 Toggle fullscreen |
| `Alt + Shift + Space` | 📌 Toggle floating |

### 🏠 Workspace Management
| Shortcut | Action |
|----------|--------|
| `Alt + 1-9` | 🏠 Switch to workspace 1-9 |
| `Alt + Shift + 1-9` | 📦 Move window to workspace 1-9 |

### 🔄 Layout Management
| Shortcut | Action |
|----------|--------|
| `Alt + s` | ↔️ Split horizontally |
| `Alt + v` | ↕️ Split vertically |
| `Alt + r` | 🔄 Reload AeroSpace config |

## 🔍 Global Shortcuts

### 📋 Clipboard (via Cliphist)
| Shortcut | Action |
|----------|--------|
| Standard copy/paste | 📋 Automatic clipboard history |
| Search via Fuzzel | 🔍 Access clipboard history |

### 🎨 Color Picker (Hyprpicker)
| Shortcut | Action |
|----------|--------|
| `Super + Shift + C` | 🎨 Pick color from screen |
| `Escape` | ❌ Cancel color picking |

## 💡 Tips

- **Vim-style navigation**: Most tools use h/j/k/l for left/down/up/right
- **Consistent modifiers**: Super for Hyprland, Ctrl+Q for Tmux, Space for Neovim
- **Mouse support**: Tmux and Hyprland support mouse interactions
- **Clipboard integration**: All tools share the system clipboard
- **Context-aware**: Tmux detects Neovim and adjusts pane navigation accordingly
