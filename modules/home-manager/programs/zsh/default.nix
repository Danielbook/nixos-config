{config, pkgs, ...}: {
  # Zsh shell configuration
  programs.zsh = {
    dotDir = "${config.xdg.configHome}/zsh";
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    plugins = [
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
        file = "share/zsh/site-functions";
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
    initContent = ''
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

      # autosuggestion styling
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#585b70"  # catppuccin surface2
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)

      # completion styling
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      # Auto-start tmux for interactive shells
      if [[ -z "$TMUX" ]] && [[ -n "$PS1" ]] && [[ -t 0 ]]; then
        # Try to attach to an existing unattached session, otherwise create a new one
        tmux attach-session -t default 2>/dev/null || tmux new-session -s default
      fi
    '';
  };
}
