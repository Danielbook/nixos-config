{
  userConfig,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../programs/atuin
    ../programs/bat
    ../programs/btop
    ../programs/carapace
    ../programs/direnv
    ../programs/fastfetch
    ../programs/fzf
    ../programs/gh
    ../programs/git
    ../programs/go
    ../programs/gpg
    ../programs/jujutsu
    ../programs/lazygit
    ../programs/neovim
    ../programs/ssh
    ../programs/starship
    ../programs/tmux
    ../programs/yazi
    ../programs/zoxide
    ../programs/zsh
    ../scripts
  ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Home-Manager configuration for the user's home environment
  home = {
    username = userConfig.name;
    homeDirectory = "/home/${userConfig.name}";
  };

  # Essential CLI packages
  home.packages = with pkgs; [
    bash
    bruno
    dig
    dust
    eza
    fd
    github-copilot-cli
    glab
    jq
    lazydocker
    nh
    openconnect
    pipenv
    python3
    ripgrep
    sesh
    television
    terraform
    unzip
    opencode
    playwright-mcp
  ];

  # Install latest claude-code and codex via npm (nixpkgs lags behind)
  home.activation.installNpmCLITools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export npm_config_prefix="$HOME/.npm-global"
    PATH="${pkgs.nodejs_24}/bin:$PATH"
    $DRY_RUN_CMD ${pkgs.nodejs_24}/bin/npm install -g \
      @anthropic-ai/claude-code@latest \
      @openai/codex@latest \
      2>&1 | tail -5
  '';

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
