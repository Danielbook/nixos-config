# CLI Tools

All command-line tools used across this NixOS configuration, organized by category.

## Shell & Terminal

| Tool | Description | Link |
|------|-------------|------|
| zsh | Shell with completions and plugins | [github.com/zsh-users/zsh](https://github.com/zsh-users/zsh) |
| bash | Bourne Again Shell (fallback) | [gnu.org/software/bash](https://www.gnu.org/software/bash/) |
| starship | Cross-shell prompt engine | [github.com/starship/starship](https://github.com/starship/starship) |
| tmux | Terminal multiplexer | [github.com/tmux/tmux](https://github.com/tmux/tmux) |
| carapace | Multi-shell completion engine | [github.com/carapace-sh/carapace-bin](https://github.com/carapace-sh/carapace-bin) |
| atuin | Shell history search and sync | [github.com/atuinsh/atuin](https://github.com/atuinsh/atuin) |
| direnv | Per-directory environment variables | [github.com/direnv/direnv](https://github.com/direnv/direnv) |
| sesh | Smart tmux session manager | [github.com/joshmedeski/sesh](https://github.com/joshmedeski/sesh) |
| zoxide | Smarter cd command | [github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) |
| fastfetch | System information display | [github.com/fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) |

## File & Text

| Tool | Description | Link |
|------|-------------|------|
| bat | Syntax-highlighted cat replacement | [github.com/sharkdp/bat](https://github.com/sharkdp/bat) |
| eza | Modern ls replacement | [github.com/eza-community/eza](https://github.com/eza-community/eza) |
| fd | Fast find alternative | [github.com/sharkdp/fd](https://github.com/sharkdp/fd) |
| ripgrep | Fast recursive grep | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| fzf | General-purpose fuzzy finder | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| television | Blazingly fast fuzzy finder TUI | [github.com/alexpasmantier/television](https://github.com/alexpasmantier/television) |
| yazi | Terminal file manager | [github.com/sxyazi/yazi](https://github.com/sxyazi/yazi) |
| jq | Command-line JSON processor | [github.com/jqlang/jq](https://github.com/jqlang/jq) |
| dust | Intuitive disk usage analyzer | [github.com/bootandy/dust](https://github.com/bootandy/dust) |
| unzip | ZIP archive extractor | — |
| tesseract | OCR engine for text recognition | [github.com/tesseract-ocr/tesseract](https://github.com/tesseract-ocr/tesseract) |

## Git & Version Control

| Tool | Description | Link |
|------|-------------|------|
| git | Version control system | [github.com/git/git](https://github.com/git/git) |
| git-lfs | Git Large File Storage | [github.com/git-lfs/git-lfs](https://github.com/git-lfs/git-lfs) |
| delta | Git diff pager with syntax highlighting | [github.com/dandavison/delta](https://github.com/dandavison/delta) |
| lazygit | Git terminal UI | [github.com/jesseduffield/lazygit](https://github.com/jesseduffield/lazygit) |
| gh | GitHub CLI | [github.com/cli/cli](https://github.com/cli/cli) |
| gh-dash | GitHub dashboard extension for gh | [github.com/dlvhdr/gh-dash](https://github.com/dlvhdr/gh-dash) |
| glab | GitLab CLI | [gitlab.com/gitlab-org/cli](https://gitlab.com/gitlab-org/cli) |
| jujutsu | Modern VCS (Git-compatible) | [github.com/jj-vcs/jj](https://github.com/jj-vcs/jj) |
| worktrunk | Git worktree management CLI | [github.com/max-sixty/worktrunk](https://github.com/max-sixty/worktrunk) |

## AI Coding Agents

| Tool | Description | Link |
|------|-------------|------|
| claude-code | Anthropic's CLI for Claude | [github.com/anthropics/claude-code](https://github.com/anthropics/claude-code) |
| codex | OpenAI's coding agent CLI | [github.com/openai/codex](https://github.com/openai/codex) |
| opencode | Open-source AI coding agent | [github.com/opencode-ai/opencode](https://github.com/opencode-ai/opencode) |
| pi | Minimal terminal coding harness, multi-provider | [github.com/badlogic/pi-mono](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) |
| github-copilot-cli | GitHub Copilot CLI | [github.com/github/copilot-cli](https://github.com/github/copilot-cli) |

## Development

| Tool | Description | Link |
|------|-------------|------|
| neovim | Hyperextensible text editor | [github.com/neovim/neovim](https://github.com/neovim/neovim) |
| go | Go programming language | [github.com/golang/go](https://github.com/golang/go) |
| python3 | Python interpreter | [github.com/python/cpython](https://github.com/python/cpython) |
| pipenv | Python virtual environment manager | [github.com/pypa/pipenv](https://github.com/pypa/pipenv) |
| nodejs | Node.js runtime | [github.com/nodejs/node](https://github.com/nodejs/node) |
| gcc | GNU C/C++ compiler | [gcc.gnu.org](https://gcc.gnu.org/) |
| gnumake | GNU Make build tool | [gnu.org/software/make](https://www.gnu.org/software/make/) |
| terraform | Infrastructure as code | [github.com/hashicorp/terraform](https://github.com/hashicorp/terraform) |
| bruno | API testing tool (Postman alternative) | [github.com/usebruno/bruno](https://github.com/usebruno/bruno) |

## Neovim LSP & Formatters

| Tool | Description | Link |
|------|-------------|------|
| nil | Nix language server | [github.com/oxalica/nil](https://github.com/oxalica/nil) |
| nixd | Nix language server (alternative) | [github.com/nix-community/nixd](https://github.com/nix-community/nixd) |
| alejandra | Nix code formatter | [github.com/kamadorueda/alejandra](https://github.com/kamadorueda/alejandra) |
| gopls | Go language server | [github.com/golang/tools](https://github.com/golang/tools) |
| pyright | Python language server | [github.com/microsoft/pyright](https://github.com/microsoft/pyright) |
| isort | Python import sorter | [github.com/PyCQA/isort](https://github.com/PyCQA/isort) |
| rust-analyzer | Rust language server | [github.com/rust-lang/rust-analyzer](https://github.com/rust-lang/rust-analyzer) |
| vtsls | TypeScript/JavaScript LSP | [github.com/yioneko/vtsls](https://github.com/yioneko/vtsls) |
| biome | JavaScript/TypeScript linter/formatter | [github.com/biomejs/biome](https://github.com/biomejs/biome) |
| prettier | Web language formatter | [github.com/prettier/prettier](https://github.com/prettier/prettier) |
| svelte-language-server | Svelte language server | [github.com/sveltejs/language-tools](https://github.com/sveltejs/language-tools) |
| tailwindcss-language-server | Tailwind CSS language server | [github.com/tailwindlabs/tailwindcss-intellisense](https://github.com/tailwindlabs/tailwindcss-intellisense) |
| lua-language-server | Lua language server | [github.com/LuaLS/lua-language-server](https://github.com/LuaLS/lua-language-server) |
| stylua | Lua code formatter | [github.com/JohnnyMorganz/StyLua](https://github.com/JohnnyMorganz/StyLua) |
| bash-language-server | Bash language server | [github.com/bash-lsp/bash-language-server](https://github.com/bash-lsp/bash-language-server) |
| shellcheck | Shell script static analysis | [github.com/koalaman/shellcheck](https://github.com/koalaman/shellcheck) |
| shfmt | Shell script formatter | [github.com/mvdan/sh](https://github.com/mvdan/sh) |
| terraform-ls | Terraform language server | [github.com/hashicorp/terraform-ls](https://github.com/hashicorp/terraform-ls) |
| markdownlint-cli | Markdown linter | [github.com/igorshubovych/markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli) |
| yaml-language-server | YAML language server | [github.com/redhat-developer/yaml-language-server](https://github.com/redhat-developer/yaml-language-server) |
| vscode-langservers-extracted | HTML/CSS/JSON language servers | [github.com/hrsh7th/vscode-langservers-extracted](https://github.com/hrsh7th/vscode-langservers-extracted) |

## System & Monitoring

| Tool | Description | Link |
|------|-------------|------|
| btop | System resource monitor | [github.com/aristocratos/btop](https://github.com/aristocratos/btop) |
| lazydocker | Docker management TUI | [github.com/jesseduffield/lazydocker](https://github.com/jesseduffield/lazydocker) |
| killall | Kill processes by name | — |
| ethtool | Ethernet device configuration | — |
| usbutils | USB utilities (lsusb) | — |
| dig | DNS lookup utility | — |
| nh | Nix helper for rebuilds | [github.com/viperML/nh](https://github.com/viperML/nh) |
| just | Modern task runner | [github.com/casey/just](https://github.com/casey/just) |
| nixos-anywhere | Remote NixOS deployment | [github.com/nix-community/nixos-anywhere](https://github.com/nix-community/nixos-anywhere) |

## Security & Networking

| Tool | Description | Link |
|------|-------------|------|
| sops | Encrypted secrets management | [github.com/getsops/sops](https://github.com/getsops/sops) |
| gpg | GNU Privacy Guard | [gnupg.org](https://gnupg.org/) |
| bitwarden-cli | Password manager CLI | [github.com/bitwarden/clients](https://github.com/bitwarden/clients) |
| openssl | SSL/TLS toolkit | [github.com/openssl/openssl](https://github.com/openssl/openssl) |
| wireguard-tools | WireGuard VPN utilities | [github.com/WireGuard/wireguard-tools](https://github.com/WireGuard/wireguard-tools) |
| openconnect | Cisco AnyConnect VPN client | [gitlab.com/openconnect/openconnect](https://gitlab.com/openconnect/openconnect) |
| openssh | SSH client/daemon | [openssh.com](https://www.openssh.com/) |

## Wayland & Desktop (CLI utilities)

| Tool | Description | Link |
|------|-------------|------|
| wl-clipboard | Wayland clipboard manager | [github.com/bugaevc/wl-clipboard](https://github.com/bugaevc/wl-clipboard) |
| grim | Wayland screenshot utility | [github.com/emersion/grim](https://github.com/emersion/grim) |
| slurp | Wayland region selector | [github.com/emersion/slurp](https://github.com/emersion/slurp) |
| wf-recorder | Wayland screen recorder | [github.com/ammen99/wf-recorder](https://github.com/ammen99/wf-recorder) |
| wlr-randr | Wayland display configuration | [github.com/emersion/wlr-randr](https://github.com/emersion/wlr-randr) |
| wlsunset | Wayland color temperature | [sr.ht/~kennylevinsen/wlsunset](https://sr.ht/~kennylevinsen/wlsunset/) |
| brightnessctl | Screen brightness control | [github.com/Hummer12007/brightnessctl](https://github.com/Hummer12007/brightnessctl) |
| socat | Socket relay (Hyprland IPC) | [github.com/3ndG4me/socat](http://www.dest-unreach.org/socat/) |
| cliphist | Clipboard history manager | [github.com/sentriz/cliphist](https://github.com/sentriz/cliphist) |
| hyprpicker | Wayland color picker | [github.com/hyprwm/hyprpicker](https://github.com/hyprwm/hyprpicker) |

## Audio

| Tool | Description | Link |
|------|-------------|------|
| yabridge | Windows VST bridge for Linux | [github.com/robbert-vdh/yabridge](https://github.com/robbert-vdh/yabridge) |
| yabridgectl | yabridge management CLI | [github.com/robbert-vdh/yabridge](https://github.com/robbert-vdh/yabridge) |

## Custom Scripts

| Script | Description |
|--------|-------------|
| `fkill` | Interactive process killer (fzf-based) |
| `hyprshot` | Hyprland screenshot tool |
| `ocr` | Screen region OCR to clipboard |
| `screen-recorder` | Toggle Wayland screen recording |
| `waybar-restart` | Restart waybar status bar |
