{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    programs.ghostty.enableConfig = lib.mkEnableOption "Ghostty configuration" // {
      default = false;
    };
  };

  config = lib.mkIf config.programs.ghostty.enableConfig {
    # Enable Ghostty via Home Manager (only on Linux, use Homebrew on Darwin)
    programs.ghostty = {
      enable = !pkgs.stdenv.isDarwin;
      settings = {
        # Font configuration
        font-family = "JetBrainsMono Nerd Font";
        font-size = 12;
        font-style = "regular";
        font-style-bold = "bold";
        font-style-italic = "italic";
        font-style-bold-italic = "bold-italic";

        # Theme and appearance
        theme = "catppuccin-macchiato";
        background = "#24273a";  # Catppuccin Macchiato base color
        background-opacity = 0.9;

        # Terminal settings
        term = "xterm-256color";
        shell-integration = "zsh";
        shell-integration-features = "cursor,sudo,title";

        # Window settings
        window-decoration = false;
        window-title-font-family = "MesloLGS Nerd Font";
        window-new-tab-position = "current";
        window-inherit-working-directory = true;
        window-inherit-font-size = true;

        # Dimensions and padding
        window-width = 170;
        window-height = 45;
        window-padding-x = 8;
        window-padding-y = 4;

        # Cursor settings
        cursor-style = "block";
        cursor-style-blink = false;

        # Copy/paste settings
        copy-on-select = "clipboard";
        click-repeat-interval = 500;

        # Scrollback
        scrollback-limit = 10000;

        # Mouse settings
        mouse-hide-while-typing = true;

        # Auto-start tmux
        command = "zsh -l -c \"tmux attach || tmux\"";
      } // lib.optionalAttrs pkgs.stdenv.isDarwin {
        # macOS specific settings
        macos-non-native-fullscreen = false;
        macos-titlebar-style = "hidden";
        macos-option-as-alt = true;
        macos-window-shadow = true;

        # macOS keybindings
        keybind = [
          "cmd+equal=increase_font_size:1"
          "cmd+minus=decrease_font_size:1"
          "cmd+zero=reset_font_size"
          "cmd+c=copy_to_clipboard"
          "cmd+v=paste_from_clipboard"
          "cmd+n=new_window"
          "cmd+t=new_tab"
          "cmd+w=close_surface"
          "cmd+shift+left_bracket=previous_tab"
          "cmd+shift+right_bracket=next_tab"
        ];
      } // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
        # Linux keybindings
        keybind = [
          "ctrl+shift+equal=increase_font_size:1"
          "ctrl+minus=decrease_font_size:1"
          "ctrl+zero=reset_font_size"
          "ctrl+shift+c=copy_to_clipboard"
          "ctrl+shift+v=paste_from_clipboard"
          "ctrl+shift+n=new_window"
          "ctrl+shift+t=new_tab"
          "ctrl+shift+w=close_surface"
          "ctrl+page_up=previous_tab"
          "ctrl+page_down=next_tab"
        ];
      };
    };

    # Generate config file manually on Darwin (since we use Homebrew Ghostty)
    xdg.configFile."ghostty/config" = lib.mkIf pkgs.stdenv.isDarwin {
      text = let
        settings = config.programs.ghostty.settings;
        macosSettings = {
          macos-non-native-fullscreen = false;
          macos-titlebar-style = "hidden";
          macos-option-as-alt = true;
          macos-window-shadow = true;
        };
        allSettings = settings // macosSettings;
        
        formatValue = v:
          if builtins.isBool v then
            if v then "true" else "false"
          else if builtins.isFloat v then
            toString v
          else
            toString v;
            
        formatSetting = name: value:
          if name == "keybind" then
            lib.concatMapStringsSep "\n" (item: "keybind = ${item}") ([
              "cmd+equal=increase_font_size:1"
              "cmd+minus=decrease_font_size:1"
              "cmd+zero=reset_font_size"
              "cmd+c=copy_to_clipboard"
              "cmd+v=paste_from_clipboard"
              "cmd+n=new_window"
              "cmd+t=new_tab"
              "cmd+w=close_surface"
              "cmd+shift+left_bracket=previous_tab"
              "cmd+shift+right_bracket=next_tab"
            ])
          else
            "${name} = ${formatValue value}";
      in
        lib.concatStringsSep "\n" (lib.mapAttrsToList formatSetting (builtins.removeAttrs allSettings ["keybind"])) + "\n" +
        formatSetting "keybind" null;
    };
  };
}
