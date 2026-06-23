{
  lib,
  config,
  ...
}:
{
  options.programs.tmux.noctaliaTheme = lib.mkEnableOption "Noctalia dynamic theming for tmux";

  config = {
    # Tmux terminal multiplexer configuration
    programs.tmux = {
      enable = true;
      baseIndex = 1;
      escapeTime = 10;
      historyLimit = 10000;
      keyMode = "vi";
      mouse = true;
      sensibleOnTop = false;
      terminal = "screen-256color";

      extraConfig = ''
        # Automatically renumber windows when one is closed
        set -g renumber-windows on

        # Set the prefix to `ctrl + a` instead of `ctrl + b`
        set -g prefix C-a
        unbind C-b

        # Use | and - to split a window vertically and horizontally instead of " and % respoectively
        unbind '"'
        unbind %
        bind v split-window -h -c "#{pane_current_path}"
        bind s split-window -v -c "#{pane_current_path}"

        # Bind Arrow keys to resize the window
        bind -n S-Down resize-pane -D 8
        bind -n S-Up resize-pane -U 8
        bind -n S-Left resize-pane -L 8
        bind -n S-Right resize-pane -R 8

        # Rename window with prefix + r
        bind r command-prompt -I "#W" "rename-window '%%'"

        # Rename pane with prefix + t
        bind t command-prompt -p "Pane title:" "select-pane -T '%%'"

        # Enable pane titles
        set -g pane-border-status top
        set -g pane-border-format " #{pane_index} #{pane_title} "

        # Reload tmux config by pressing prefix + R
        bind R source-file ~/.config/tmux/tmux.conf \; display "TMUX Conf Reloaded"

        # Clear screen with prefix + l
        bind C-l send-keys 'C-l'

        # Sesh session picker (prefix + f)
        bind-key "f" run-shell "sesh connect \"$(
          sesh list --icons | fzf-tmux -p 55%,60% \
            --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
            --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
            --preview 'sesh preview {2..}' --preview-window 'right:55%' \
            --bind 'tab:down,btab:up' \
            --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
            --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
            --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
            --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
            --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
            --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
        )\""

        # Copy mode improvements
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
        bind-key -T copy-mode-vi r send-keys -X rectangle-toggle
        # Mouse drag-select copies to the macOS clipboard (otherwise it only
        # lands in tmux's internal buffer and never reaches pbcopy).
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

        # Apply Tc for various terminal types
        set -ga terminal-overrides ",xterm-256color:RGB:smcup@:rmcup@"
        set -ga terminal-overrides ",xterm-kitty:RGB:smcup@:rmcup@"
        set -ga terminal-overrides ",alacritty:RGB:smcup@:rmcup@"

        # Enable focus-events
        set -g focus-events on

        # Set default escape-time
        set-option -sg escape-time 10

        # Smart pane switching with awareness of Vim splits
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf|atuin)(diff)?$'"
        bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
        bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
        bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
        bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'

        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R

        # Status bar position
        set -g status-position top

        # Status bar update interval (1 second for clock)
        set -g status-interval 1

        ${lib.optionalString config.programs.tmux.noctaliaTheme ''
          # Source Noctalia-generated colors (if available)
          if-shell "[ -f ~/.config/tmux/noctalia-colors.conf ]" {
            source-file ~/.config/tmux/noctalia-colors.conf
          }
        ''}
      '';
    };

    # Copy template file for Noctalia to process
    xdg.configFile."tmux/noctalia-template.conf" = lib.mkIf config.programs.tmux.noctaliaTheme {
      source = ./noctalia-template.conf;
    };

    # Catppuccin theming for tmux (disabled when using Noctalia)
    catppuccin = lib.mkIf (!config.programs.tmux.noctaliaTheme) {
      tmux = {
        enable = true;
        extraConfig = ''
          set -g @catppuccin_flavor "macchiato"
          set -g @catppuccin_status_background "none"

          # Window styling with beautiful separators
          set -g @catppuccin_window_current_number_color "#{@thm_peach}"
          set -g @catppuccin_window_current_text " #W"
          set -g @catppuccin_window_current_text_color "#{@thm_bg}"
          set -g @catppuccin_window_current_background_color "#{@thm_peach}"

          set -g @catppuccin_window_number_color "#{@thm_blue}"
          set -g @catppuccin_window_text " #W"
          set -g @catppuccin_window_text_color "#{@thm_surface_0}"
          set -g @catppuccin_window_background_color "#{@thm_surface_0}"

          # Separators
          set -g @catppuccin_status_left_separator "█"
          set -g @catppuccin_status_right_separator "█"
          set -g @catppuccin_window_left_separator "█"
          set -g @catppuccin_window_right_separator "█"
          set -g @catppuccin_window_middle_separator "█"
          set -g @catppuccin_window_status_separator " "

          # Status modules styling
          set -g @catppuccin_status_modules_right "directory user host session date_time"
          set -g @catppuccin_status_modules_left ""

          # Date/Time format
          set -g @catppuccin_date_time_text "%Y-%m-%d %H:%M:%S"
          set -g @catppuccin_date_time_icon "󰃰"
          set -g @catppuccin_date_time_color "#{@thm_blue}"

          # User module
          set -g @catppuccin_user_icon ""
          set -g @catppuccin_user_color "#{@thm_green}"
          set -g @catppuccin_user_text "#(whoami)"

          # Host module
          set -g @catppuccin_host_icon "󰒋"
          set -g @catppuccin_host_color "#{@thm_mauve}"
          set -g @catppuccin_host_text "#H"

          # Directory module
          set -g @catppuccin_directory_icon "󰉋"
          set -g @catppuccin_directory_color "#{@thm_lavender}"
          set -g @catppuccin_directory_text "#{pane_current_path}"

          # Session module
          set -g @catppuccin_session_icon ""
          set -g @catppuccin_session_color "#{@thm_yellow}"

          # Pane border styling
          set -g @catppuccin_pane_border_style "fg=#{@thm_surface_0}"
          set -g @catppuccin_pane_active_border_style "fg=#{@thm_lavender}"

          # Status bar position
          set -g status-position top

          # Status bar update interval (1 second for clock)
          set -g status-interval 1
        '';
      };
    };
  };
}
