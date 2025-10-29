{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    programs.kitty.enableConfig =
      lib.mkEnableOption "Kitty configuration"
      // {
        default = true;
      };
  };

  config = lib.mkIf config.programs.kitty.enableConfig {
    programs.kitty = {
      enable = true;

      # Font configuration
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 12;
      };

      settings = {
        # Catppuccin Macchiato colors
        background = "#000000";
        foreground = "#cad3f5";
        cursor = "#f4dbd6";
        selection_background = "#5b6078";
        selection_foreground = "#cad3f5";

        # Catppuccin Macchiato palette
        color0 = "#494d64"; # black
        color1 = "#ed8796"; # red
        color2 = "#a6da95"; # green
        color3 = "#eed49f"; # yellow
        color4 = "#8aadf4"; # blue
        color5 = "#f5bde6"; # magenta
        color6 = "#8bd5ca"; # cyan
        color7 = "#b8c0e0"; # white
        color8 = "#5b6078"; # bright black
        color9 = "#ed8796"; # bright red
        color10 = "#a6da95"; # bright green
        color11 = "#eed49f"; # bright yellow
        color12 = "#8aadf4"; # bright blue
        color13 = "#f5bde6"; # bright magenta
        color14 = "#8bd5ca"; # bright cyan
        color15 = "#a5adcb"; # bright white

        # Apple glass effect
        background_opacity = "0.7";
        background_blur = 50;

        # Window settings
        window_padding_width = 8;
        window_padding_height = 4;
        hide_window_decorations = "yes";
        remember_window_size = "no";
        initial_window_width = 170;
        initial_window_height = 45;

        # Cursor settings
        cursor_shape = "block";
        cursor_blink_interval = 0;

        # Mouse settings
        mouse_hide_wait = 3.0;
        copy_on_select = "clipboard";

        # Scrollback
        scrollback_lines = 10000;

        # Shell integration
        shell_integration = "enabled";

        # Tab bar
        tab_bar_edge = "top";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";

        # Performance
        repaint_delay = 10;
        input_delay = 3;
        sync_to_monitor = "yes";

        # Advanced
        allow_remote_control = "yes";
        listen_on = "unix:/tmp/kitty";

        # Disable audio bell
        enable_audio_bell = "no";
        visual_bell_duration = 0;
      };

      # Keybindings
      keybindings = {
        # Font size
        "ctrl+shift+equal" = "change_font_size all +1.0";
        "ctrl+shift+minus" = "change_font_size all -1.0";
        "ctrl+shift+0" = "change_font_size all 0";

        # Clipboard
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";

        # Tabs
        "ctrl+shift+t" = "new_tab";
        "ctrl+shift+w" = "close_tab";
        "ctrl+shift+right" = "next_tab";
        "ctrl+shift+left" = "previous_tab";

        # Windows
        "ctrl+shift+n" = "new_window";
        "ctrl+shift+q" = "close_window";

        # Layouts
        "ctrl+shift+l" = "next_layout";
      };

      # Shell startup command (auto-attach tmux like ghostty)
      shellIntegration.enableZshIntegration = true;
    };

    # Add tmux auto-attach to zsh if kitty is running
    programs.zsh.initContent = lib.mkAfter ''
      if [[ "$TERM" == "xterm-kitty" ]] && [[ -z "$TMUX" ]]; then
        tmux list-sessions 2>/dev/null | grep -v '(attached)' && tmux attach-session || tmux new-session
      fi
    '';
  };
}
