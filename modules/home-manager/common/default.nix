{
  userConfig,
  pkgs,
  ...
}: {
  imports = [
    ../programs/alacritty
    ../programs/atuin
    ../programs/bat
    ../programs/brave
    ../programs/btop
    ../programs/carapace
    ../programs/direnv
    ../programs/fastfetch
    ../programs/firefox
    ../programs/fuzzel
    ../programs/fzf
    ../programs/ghostty
    ../programs/git
    ../programs/go
    ../programs/gpg
    ../programs/jujutsu
    ../programs/kitty
    ../programs/lazygit
    ../programs/neovim
    ../programs/obs-studio
    ../programs/ssh
    ../programs/starship
    ../programs/tmux
    ../programs/vscode
    # ../programs/vscodium
    ../programs/yabridge
    ../programs/yazi
    ../programs/zoxide
    ../programs/zsh
    ../scripts
    ../services/easyeffects
    ../services/flatpak
  ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Home-Manager configuration for the user's home environment
  home = {
    username = userConfig.name;
    homeDirectory = "/home/${userConfig.name}";
  };

  # Essential user packages for daily workflow (Linux)
  home.packages = with pkgs; [
    # Cross-platform packages
    bash # Bash shell (fallback/compatibility)
    bruno # Open-source API testing tool (Postman alternative)
    dig # DNS lookup utility
    dust # Modern disk usage analyzer (du replacement)
    eza # Modern ls replacement with colors and icons
    fd # Fast find alternative for files/directories
    github-copilot-cli # GitHub Copilot CLI
    glab # GitLab CLI for managing repos, issues, MRs
    jq # JSON processor and formatter
    lazydocker # Docker container management TUI
    nh # NixOS helper for rebuilding and managing generations
    openconnect # Cisco AnyConnect VPN client
    pipenv # Python virtual environment manager
    python3 # Python 3 interpreter
    ripgrep # Fast grep alternative with better defaults
    terraform # Infrastructure as code tool
    unzip # Archive extraction utility
    claude-code # Claude Code editor
    codex # OpenAI Codex CLI coding agent
    opencode # Open-source AI coding agent for the terminal
    playwright-mcp # Playwright MCP server with pre-patched browsers

    # Linux-specific packages
    # google-chrome # Moved to host-specific config with custom flags
    prusa-slicer # 3D printer slicer for Prusa printers
    satty # Modern Wayland screenshot annotation tool (replaces swappy)
    # awww # Wayland wallpaper daemon (provided via flake input in services/awww)
    tesseract # OCR engine for text recognition
    wl-clipboard # Wayland clipboard manager
    xdg-desktop-portal # Desktop integration portal
    xdg-desktop-portal-hyprland # Hyprland-specific desktop portal
    xterm # X terminal emulator (fallback)
  ];

  # Claude Code global settings
  home.file.".claude/settings.json".text = builtins.toJSON {
    enabledPlugins = {
      "frontend-design@claude-code-plugins" = true;
    };
    alwaysThinkingEnabled = true;
    permissions = {
      allowedTools = ["Read" "Write" "Edit" "Glob" "Grep" "Bash" "Task"];
      allow = [
        "Bash(*)"
        "Read(*)"
        "WebSearch"
        "WebFetch"
        "mcp__playwright__*"
      ];
      deny = [
        # Env files and secrets
        "Read(.env)" "Read(.env.*)" "Read(*/.env)" "Read(*/.env.*)"
        "Write(.env)" "Write(.env.*)" "Write(*/.env)" "Write(*/.env.*)"
        # Private keys and credentials
        "Read(*.pem)" "Read(*.key)" "Read(*.p12)" "Read(*.pfx)"
        "Read(*id_rsa*)" "Read(*id_ed25519*)" "Read(*id_ecdsa*)" "Read(*id_dsa*)"
        "Read(*credential*)" "Read(*secret*)"
        "Read(.npmrc)" "Read(.pypirc)" "Read(.netrc)"
        "Read(~/.aws/*)" "Read(~/.kube/config)" "Read(~/.docker/config.json)"
        "Read(~/.gcloud/*)" "Read(~/.azure/*)"
        # Protected config dirs
        "Write(~/.ssh/*)" "Write(~/.aws/*)" "Write(~/.kube/*)"
        "Write(~/.docker/*)" "Write(~/.gcloud/*)" "Write(~/.azure/*)"
        "Write(~/.bashrc)" "Write(~/.zshrc)" "Write(~/.profile)"
        "Write(.npmrc)" "Write(.pypirc)" "Write(.netrc)"
        # Destructive git operations
        "Bash(git add *)" "Bash(git add)" "Bash(git rm *)" "Bash(git mv *)"
        "Bash(git commit *)" "Bash(git commit)"
        "Bash(git merge *)" "Bash(git rebase *)" "Bash(git reset *)"
        "Bash(git revert *)" "Bash(git cherry-pick *)"
        "Bash(git push *)" "Bash(git push)" "Bash(git pull *)" "Bash(git pull)"
        "Bash(git clone *)" "Bash(git init *)" "Bash(git init)"
        "Bash(git am *)" "Bash(git apply *)" "Bash(git clean *)"
        "Bash(git checkout -- *)" "Bash(git checkout -b *)" "Bash(git checkout -B *)"
        "Bash(git checkout --orphan *)"
        "Bash(git switch -c *)" "Bash(git switch -C *)" "Bash(git switch --create *)"
        "Bash(git stash push *)" "Bash(git stash push)" "Bash(git stash save *)" "Bash(git stash save)"
        "Bash(git stash pop *)" "Bash(git stash pop)" "Bash(git stash drop *)" "Bash(git stash drop)"
        "Bash(git stash apply *)" "Bash(git stash apply)" "Bash(git stash clear)" "Bash(git stash branch *)"
        "Bash(git branch -d *)" "Bash(git branch -D *)" "Bash(git branch -m *)" "Bash(git branch -M *)"
        "Bash(git branch -c *)" "Bash(git branch -C *)"
        "Bash(git branch --delete *)" "Bash(git branch --move *)" "Bash(git branch --copy *)"
        "Bash(git tag -d *)" "Bash(git tag -a *)" "Bash(git tag -s *)" "Bash(git tag -f *)" "Bash(git tag --delete *)"
        "Bash(git remote add *)" "Bash(git remote remove *)" "Bash(git remote rm *)"
        "Bash(git remote rename *)" "Bash(git remote set-url *)" "Bash(git remote set-head *)" "Bash(git remote prune *)"
        "Bash(git submodule add *)" "Bash(git submodule init *)" "Bash(git submodule update *)"
        "Bash(git submodule deinit *)" "Bash(git submodule sync *)"
        "Bash(git worktree add *)" "Bash(git worktree remove *)" "Bash(git worktree move *)" "Bash(git worktree prune *)"
        "Bash(git config --global *)" "Bash(git config --system *)" "Bash(git config --unset *)"
        "Bash(git config --add *)" "Bash(git config --remove-section *)" "Bash(git config --rename-section *)"
        "Bash(git notes add *)" "Bash(git notes remove *)" "Bash(git notes edit *)" "Bash(git notes merge *)" "Bash(git notes prune *)"
        "Bash(git filter-branch *)" "Bash(git filter-repo *)" "Bash(git gc *)" "Bash(git gc)"
        "Bash(git prune *)" "Bash(git reflog expire *)" "Bash(git reflog delete *)" "Bash(git update-ref *)"
        # Dangerous system commands
        "Bash(rm -rf /)" "Bash(rm -rf /*)" "Bash(rm -rf ~/*)"
        "Bash(sudo *)" "Bash(pkexec *)" "Bash(su *)" "Bash(su)"
        "Bash(chmod 777 *)" "Bash(crontab *)"
      ];
    };
    hooks = {
      Stop = [{
        hooks = [{
          type = "command";
          command = ''SA_BASE="''${CLAUDE_PROJECT_DIR:-.}/.claude/sa/.sessions/.id-gen"; [ -d "$SA_BASE" ] && find "$SA_BASE" -maxdepth 1 -mindepth 1 -type d -empty -delete 2>/dev/null || true'';
          timeout = 5;
        }];
      }];
    };
  };

  # Catpuccin flavor and accent
  catppuccin = {
    flavor = "macchiato";
    accent = "lavender";
  };
}
