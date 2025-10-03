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

        # Theme and appearance (manual Catppuccin Macchiato colors)
        background = "#24273a";
        foreground = "#cad3f5";
        cursor-color = "#f4dbd6";
        selection-background = "#5b6078";
        selection-foreground = "#cad3f5";
        
        # Catppuccin Macchiato palette - remove this since we need individual palette entries
        
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
            
        # Catppuccin Macchiato palette entries
        paletteEntries = [
          "palette = 0=#494d64"   # black
          "palette = 1=#ed8796"   # red
          "palette = 2=#a6da95"   # green
          "palette = 3=#eed49f"   # yellow
          "palette = 4=#8aadf4"   # blue
          "palette = 5=#f5bde6"   # magenta
          "palette = 6=#8bd5ca"   # cyan
          "palette = 7=#b8c0e0"   # white
          "palette = 8=#5b6078"   # bright black
          "palette = 9=#ed8796"   # bright red
          "palette = 10=#a6da95"  # bright green
          "palette = 11=#eed49f"  # bright yellow
          "palette = 12=#8aadf4"  # bright blue
          "palette = 13=#f5bde6"  # bright magenta
          "palette = 14=#8bd5ca"  # bright cyan
          "palette = 15=#a5adcb"  # bright white
        ];
      in
        lib.concatStringsSep "\n" (lib.mapAttrsToList formatSetting (builtins.removeAttrs allSettings ["keybind"])) + "\n" +
        formatSetting "keybind" null + "\n" +
        lib.concatStringsSep "\n" paletteEntries;
    };
  };
}
