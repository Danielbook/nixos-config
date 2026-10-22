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
| pi | Minimal terminal coding harness, multi-provider | [github.com/earendil-works/pi](https://github.com/earendil-works/pi) |
| github-copilot-cli | GitHub Copilot CLI | [github.com/github/copilot-cli](https://github.com/github/copilot-cli) |

> **Install method:** the `installAgents` activation in
> `modules/home-manager/programs/agents/default.nix` installs `codex` and `pi`
> from npm on both platforms. It installs claude-code from npm on Linux only,
> with `DISABLE_AUTOUPDATER=1`. On macOS, Claude Code uses its native
> self-updating installer (`claude install` → `~/.local/bin/claude`). Claude
> Code user data (settings, skills, plugins, MCP) lives in `~/.claude/` for
> either binary.

All agent config lives in `modules/home-manager/programs/agents/`. Each agent
gets the same [MCP servers](#mcp-servers), the same [agent
policy](#agent-policy) and the same instructions file (`agent-instructions.md`,
linked to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` and `~/.pi/agent/AGENTS.md`).

### Pi configuration

- `programs/agents/pi/default.nix` owns package pins (Ponytail, web search,
  subagents, ask-user-question) and startup preferences. It renders the Pi MCP
  servers from the shared registry. `pi-mcp-adapter` is not loaded.
- After `installAgents`, the Pi activation merges managed keys into writable
  `~/.pi/agent/settings.json` and `mcp.json`, then reconciles packages with
  `pi update --extensions --no-approve`. Unmanaged settings and other MCP
  servers are preserved. Changes to managed keys through Pi are reset at the
  next activation; edit Nix to persist them.
- Skills are not Nix-managed: Pi discovers `~/.agents/skills` natively, the
  same directory the `skills` CLI installs into for Claude Code.
- Auth, sessions, model catalogs and package caches remain local. Never copy
  credentials into these Nix files: the Nix store is readable by other users.

### MCP servers

`programs/agents/mcp-servers.nix` defines each MCP server once. To add a
server, add an entry to that file. An entry sets `command` and `args` (stdio)
or `url` (remote HTTP). `agents` lists the agents that get the server: `"pi"`,
`"claude"` and `"codex"`. Keys under `pi`, for example `toolExposure` and
`oauth.clientName`, go only into the Pi config.

Three adapters render the registry:

- Pi: `pi/default.nix` writes `pi-mcp.json`. Activation merges it into
  `~/.pi/agent/mcp.json`.
- Claude Code: the `registerClaudeMcp` activation in `claude.nix` merges the
  servers into `mcpServers` in `~/.claude.json`. A `url` server gets `type:
  "http"`, and other servers get `type: "stdio"`. Each server also gets an
  allow rule `mcp__<name>__*`.
- Codex: the `registerCodexMcp` activation in `codex.nix` runs `codex-mcp.py`.
  The script replaces the `[mcp_servers.<name>]` tables in
  `~/.codex/config.toml` and keeps all other keys and comments.

Each merge replaces only the managed keys. Servers that you add by hand stay.
A server that you delete from the registry also stays, so delete it by hand.
Remote OAuth servers (Figma, Miro) need one sign-in per agent: `pi mcp login
<name>` in Pi, `/mcp` in Claude Code, `codex mcp login <name>` in Codex.

### Agent policy

`programs/agents/policy.nix` holds the secret paths and the command tiers that
each agent enforces:

- `secretNames` and `secretPaths`: no read or write. `protectedPaths`: no write.
- `deny`: command prefixes that are blocked with no question.
- `ask`: command prefixes that need a yes each time.

The adapters render the policy as follows:

| Agent | Secret paths | Commands |
|-------|--------------|----------|
| Claude Code | `Read`/`Edit` deny rules | `Bash(...)` deny and ask rules |
| Pi | `safety-gates.ts` checks file tools and bash text | `safety-gates.ts` blocks or asks |
| Codex | not enforced (permission profiles are beta) | `~/.codex/rules/nix.rules` (`forbidden`, `prompt`) |

Nix owns the whole `permissions` key of `~/.claude/settings.json` and writes it
on each switch. A permission that you add by hand in user settings disappears
at the next switch. Put it in `policy.nix` or in a project
`.claude/settings.local.json`. Codex writes its "always allow" answers to
`~/.codex/rules/default.rules`. Nix does not touch that file.

Claude Code and Codex match a prefix token by token from the start. Thus `rm
-fr` does not match `rm -rf` there. Pi also matches flags in any order and
combined short flags. If `safety-policy.json` is missing, Pi blocks every tool
call.

### codebase-memory-mcp

Code knowledge-graph MCP server (nixpkgs build), registered for Pi, Claude Code
and Codex through the [MCP registry](#mcp-servers). All three use the same
store binary. Thus they share one daemon and the per-machine graph in
`~/.cache/codebase-memory-mcp/`. Nothing goes into a repo unless
`index_repository` runs with `persistence: true`. Index a repo once with "index
this project". After that, the watcher keeps git repos fresh.

`wt` worktrees are separate paths. Thus the user wt config
(`~/.config/worktrunk/config.toml`, from `programs/agents/default.nix`) indexes
each new worktree in a `post-start` hook and deletes its graph in `post-remove`.

In Pi the query tools (`search_graph`, `trace_path`, `get_code_snippet`,
`query_graph`, `search_code`, `get_architecture`, `index_status`) have `direct`
exposure. The default `codemode` of Pi hides them, and Pi did not use them.
Direct exposure alone was not enough. The shared instruction file must make
the graph the first step and give the path-derived project name.
- macOS Playwright retains the writable browser cache and uses Chrome;
  Linux uses Nix's bundled Chromium. Browser downloads are runtime state.
- Pins control selected package versions/refs; npm transitive dependencies
  still resolve at activation time. This is not a fully offline, Nix-locked
  dependency closure.

Validate the Pi config merge and the safety gate without a change to live
settings:

```bash
node --test 'modules/home-manager/programs/agents/pi/**/*.test.mjs'
```

Check the Codex rules after a build (`$G` is the home-manager generation):

```bash
codex execpolicy check --pretty --rules $G/home-files/.codex/rules/nix.rules -- rm -rf /
```

Apply through `just home-manager-switch`, then restart each agent. New snapshot files
must be tracked in Git before the normal Git-flake rebuild sees them.

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
