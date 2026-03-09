{config, lib, pkgs, ...}: {
  # Zsh shell configuration
  programs.zsh = {
    dotDir = "${config.xdg.configHome}/zsh";
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    autosuggestion = {
      enable = true;
      highlight = "fg=#585b70";
      strategy = ["history" "completion"];
    };

    plugins = [
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
        file = "share/zsh/site-functions";
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

    shellAliases = {
      ff = "fastfetch";

      # git
      gaa = "git add --all";
      gcam = "git commit --all --message";
      gcl = "git clone";
      gco = "git checkout";
      ggl = "git pull";
      ggp = "git push";

      # jujutsu
      jjpush = "jj bookmark set main -r @ && jj push";

      ld = "lazydocker";
      lg = "lazygit";

      repo = "cd $HOME/Documents/repositories";
      temp = "cd $HOME/Downloads/temp";

      v = "nvim";
      vi = "nvim";
      vim = "nvim";

      ls = "eza --icons always"; # default view
      ll = "eza -bhl --icons --group-directories-first"; # long list
      la = "eza -abhl --icons --group-directories-first"; # all list
      lt = "eza --tree --level=2 --icons"; # tree
    };

    initContent = lib.mkMerge [
      # Completion styling + fzf-tab config (loads right after compinit at 570)
      (lib.mkOrder 580 ''
        # Case-insensitive, partial-word, and substring completion
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

        # Group completions by category
        zstyle ':completion:*' group-name '''
        zstyle ':completion:*:descriptions' format '[%d]'

        # Colorize file completions using LS_COLORS
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

        # Show descriptions in completions
        zstyle ':completion:*' verbose yes

        # fzf-tab configuration
        zstyle ':fzf-tab:*' switch-group '<' '>'
        zstyle ':fzf-tab:*' continuous-trigger '/'

        # Previews: directories
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
        zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --color=always --icons $realpath'

        # Previews: files (bat for known files, fallback to directory listing)
        zstyle ':fzf-tab:complete:*:*' fzf-preview \
          '([[ -f $realpath ]] && bat --color=always --style=numbers --line-range=:200 $realpath) \
          || ([[ -d $realpath ]] && eza -1 --color=always --icons $realpath) \
          || echo $realpath 2>/dev/null'

        # Previews: git
        zstyle ':fzf-tab:complete:git-(checkout|diff|log|merge|rebase|reset|switch):*' fzf-preview \
          'git log --oneline --graph --color=always --date=short $word 2>/dev/null'

        # Previews: systemctl
        zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word 2>/dev/null'

        # Previews: environment variables
        zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview \
          'echo "''${(P)word}"'
      '')

      # vi-mode, keybindings, tmux auto-start (default order 1000)
      ''
        # Source home-manager session variables
        [[ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]] && source ~/.nix-profile/etc/profile.d/hm-session-vars.sh

        # vi mode
        bindkey -v

        # vi mode bindings
        bindkey '^H' backward-delete-word
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
        bindkey '^R' history-incremental-search-backward
        bindkey '^P' up-history
        bindkey '^N' down-history

        # open commands in $EDITOR with C-e
        autoload -z edit-command-line
        zle -N edit-command-line
        bindkey "^v" edit-command-line

        # autosuggestion key bindings
        bindkey '^[[Z' autosuggest-accept  # shift-tab to accept suggestion
        bindkey '^I' complete-word         # tab for completion

        # Auto-start tmux for interactive shells
        if [[ -z "$TMUX" ]] && [[ -n "$PS1" ]] && [[ -t 0 ]]; then
          # Try to attach to an existing unattached session, otherwise create a new one
          tmux attach-session -t default 2>/dev/null || tmux new-session -s default
        fi
      ''

      # Worktrunk (wt) shell integration — must load after compinit
      (lib.mkOrder 1100 ''
        eval "$(wt config shell init zsh)"
      '')
    ];
  };
}
