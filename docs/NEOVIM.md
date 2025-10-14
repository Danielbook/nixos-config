# 📝 Neovim Configuration

> Modern Neovim setup with LSP, Treesitter, Telescope, and Git integration via vim-fugitive

## 📦 Plugin Stack

### Core Editing
- **nvim-lspconfig** - Language Server Protocol client
- **nvim-treesitter** - Advanced syntax highlighting and parsing
- **nvim-cmp** - Autocompletion engine
- **luasnip** - Snippet engine
- **which-key-nvim** - Keybinding help and documentation

### Navigation & Search
- **telescope.nvim** - Fuzzy finder for files, buffers, grep
- **neo-tree.nvim** - File explorer tree
- **telescope-fzf-native** - FZF integration for Telescope

### Git Integration
- **vim-fugitive** - Complete Git workflow integration
- **gitsigns.nvim** - Git signs in the gutter with hunk operations

### UI & Aesthetics
- **catppuccin-nvim** - Beautiful pastel colorscheme
- **lualine.nvim** - Fast and customizable statusline
- **alpha-nvim** - Custom startup dashboard
- **noice.nvim** - Better UI for messages, cmdline and popupmenu
- **nvim-notify** - Beautiful notification system
- **indent-blankline.nvim** - Animated indent guides
- **mini.nvim** - Collection of small plugins including animate

### Utilities
- **none-ls-nvim** - Formatters and linters integration
- **undotree** - Undo history visualizer
- **peek.nvim** - Markdown preview
- **vim-be-good** - Vim practice game

## ⌨️ Keybindings

### Leader Key
The leader key is set to `<Space>`.

### File & Search Operations (`<leader>f`)

| Keybind | Action |
|---------|--------|
| `<leader>ff` | Find Files |
| `<leader>fb` | Find Buffers |
| `<leader>fw` | Find Word under cursor |
| `<leader>fW` | Find WORD under cursor |
| `<leader>fh` | Find Help |
| `<leader>f` | Format Buffer |

### Search/Grep Operations (`<leader>s`)

| Keybind | Action |
|---------|--------|
| `<leader>sg` | Live Grep |
| `<leader>/` | Fuzzy search in current buffer |

### Git Operations (`<leader>g`) - Fugitive

| Keybind | Action |
|---------|--------|
| `<leader>gs` | Git Status (opens fugitive interface) |
| `<leader>gc` | Git Commit |
| `<leader>gp` | Git Push |
| `<leader>gP` | Git Pull |
| `<leader>gb` | Git Blame |
| `<leader>gd` | Git Diff (split view) |
| `<leader>gl` | Git Log |
| `<leader>gL` | Git Log (current file) |
| `<leader>gr` | Git Read (checkout file) |
| `<leader>gw` | Git Write (stage file) |

### Git Hunks (`<leader>h`) - GitSigns

| Keybind | Action | Mode |
|---------|--------|------|
| `<leader>hs` | Stage Hunk | n, v |
| `<leader>hr` | Reset Hunk | n, v |
| `<leader>hS` | Stage Buffer | n |
| `<leader>hu` | Undo Stage Hunk | n |
| `<leader>hR` | Reset Buffer | n |
| `<leader>hp` | Preview Hunk | n |
| `<leader>hb` | Blame Line (full) | n |
| `<leader>hd` | Diff This | n |
| `<leader>hD` | Diff This ~ | n |
| `[c` | Previous Git Hunk | n |
| `]c` | Next Git Hunk | n |
| `ih` | Inner Hunk (text object) | o, x |

### Code Operations (`<leader>c`)

| Keybind | Action |
|---------|--------|
| `<leader>ca` | Code Actions |
| `<leader>cf` | Quick Fix Diagnostic |

### Diagnostics (`<leader>d`)

| Keybind | Action |
|---------|--------|
| `<leader>ds` | Document Symbols |
| `[d` | Previous Diagnostic |
| `]d` | Next Diagnostic |

### Rename/Refactor (`<leader>r`)

| Keybind | Action |
|---------|--------|
| `<leader>rn` | Rename Symbol |

### View Operations (`<leader>v`)

| Keybind | Action |
|---------|--------|
| `<leader>vd` | View Diagnostics Float |

### Workspace (`<leader>w`)

| Keybind | Action |
|---------|--------|
| `<leader>ws` | Workspace Symbols |
| `<leader>w` | Save File |

### Toggle Operations (`<leader>t`)

| Keybind | Action |
|---------|--------|
| `<leader>th` | Toggle Inlay Hints |
| `<leader>tb` | Toggle Line Blame (GitSigns) |
| `<leader>td` | Toggle Deleted Lines (GitSigns) |

### Neotree (`<leader>n`)

| Keybind | Action |
|---------|--------|
| `<C-n>` | Toggle File Explorer |
| `<leader>nb` | Show Buffer List (float) |

### LSP Navigation

| Keybind | Action |
|---------|--------|
| `K` | Hover Documentation |
| `gd` | Go to Definition |
| `gi` | Go to Implementation |
| `gt` | Go to Type Definition |
| `gr` | Go to References |

### Window Navigation

| Keybind | Action |
|---------|--------|
| `<C-h>` | Window Left |
| `<C-j>` | Window Down |
| `<C-k>` | Window Up |
| `<C-l>` | Window Right |

### Scrolling

| Keybind | Action |
|---------|--------|
| `<C-d>` | Scroll Down (centered) |
| `<C-u>` | Scroll Up (centered) |
| `<C-f>` | Page Down (centered) |
| `<C-b>` | Page Up (centered) |

### Other Useful Keybinds

| Keybind | Action | Mode |
|---------|--------|------|
| `<C-p>` | Find Git Files | n |
| `<leader>pv` | Open File Explorer (Ex) | n |
| `<leader>q` | Quit | n |
| `<leader>u` | Toggle Undo Tree | n |
| `<leader>R` | Reload Neovim Config | n |
| `<leader>p` | Paste without overwriting register | x |
| `<leader>y` | Yank to system clipboard | n, v |
| `<leader>Y` | Yank line to system clipboard | n |
| `<C-c>` | Exit Insert Mode | i |
| `<C-s>` | Signature Help | i |

## 🎨 Theme

The configuration uses **Catppuccin Mocha** theme with transparency enabled for a modern, aesthetically pleasing appearance.

## 🛠️ Language Servers

The following language servers are pre-configured:

- **Lua** - lua-language-server
- **Nix** - nil, nixd
- **Go** - gopls
- **TypeScript/JavaScript** - typescript-language-server
- **Bash** - bash-language-server
- **Python** - (isort for imports)
- **HTML/CSS/JSON** - vscode-langservers-extracted
- **YAML** - yaml-language-server
- **Tailwind CSS** - tailwindcss-language-server
- **Terraform** - terraform-ls
- **Markdown** - markdownlint-cli

## 🔧 Formatters & Linters

- **alejandra** - Nix formatter
- **prettier** - Web languages formatter
- **stylua** - Lua formatter
- **shfmt** - Shell script formatter
- **shellcheck** - Shell script analysis
- **markdownlint** - Markdown linter

## 📁 Configuration Structure

```
modules/home-manager/programs/neovim/
├── default.nix                      # Main Nix configuration
└── neovim/
    ├── init.lua                     # Neovim entry point
    └── lua/danbo/
        ├── init.lua                 # Core initialization
        ├── set.lua                  # Vim options
        ├── remap.lua                # Keybindings
        ├── which-key.lua            # Keybinding documentation
        ├── lsp.lua                  # LSP configuration
        ├── treesitter.lua           # Treesitter config
        ├── telescope.lua            # Telescope config
        ├── cmp.lua                  # Completion config
        ├── gitsigns.lua             # GitSigns config
        ├── formatting.lua           # Formatter config
        ├── catppuccin.lua           # Theme config
        ├── lualine.lua              # Statusline config
        ├── alpha.lua                # Startup screen
        ├── noice.lua                # UI enhancements
        ├── notify.lua               # Notifications
        ├── mini-animate.lua         # Animations
        └── indent-blankline.lua     # Indent guides
```

## 🚀 Usage Tips

### Fugitive Workflow

1. **View Status**: `<leader>gs` - Opens the fugitive status window
   - Press `-` to stage/unstage files
   - Press `=` to toggle inline diff
   - Press `cc` to commit
   - Press `ca` to amend last commit

2. **Commit Changes**: `<leader>gc` - Opens commit buffer
   - Write your commit message
   - Save and close (`:wq`) to complete commit

3. **Diff Changes**: `<leader>gd` - Opens a split diff view
   - Use `diffget` and `diffput` to resolve conflicts
   - Navigate between changes with `]c` and `[c`

4. **Git Blame**: `<leader>gb` - See who changed what and when

5. **Git Log**:
   - `<leader>gl` - Full repository log
   - `<leader>gL` - Log for current file only

### Telescope Quick Search

- **Files**: `<leader>ff` or `<C-p>` (Git files)
- **Live Grep**: `<leader>sg` - Search across all files
- **Buffer Search**: `<leader>fb` - Switch between open buffers
- **Help**: `<leader>fh` - Search Neovim help docs

### LSP Features

- **Hover Documentation**: Press `K` over any symbol
- **Go to Definition**: `gd`
- **Find References**: `gr`
- **Rename Symbol**: `<leader>rn`
- **Code Actions**: `<leader>ca`
- **Quick Fix**: `<leader>cf` - Apply preferred fix automatically

## 🔄 Reloading Config

Press `<leader>R` to reload your Neovim configuration without restarting.

## 🎯 Next Steps

1. Explore `:Telescope` commands
2. Try `:Git` for full fugitive power
3. Use `:Mason` to manage additional LSP servers
4. Practice with `:VimBeGood` game

---

**Configuration managed declaratively with Nix** | **Part of [Daniel's Nix Configuration](../README.md)**
