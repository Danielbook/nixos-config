{
  nhModules,
  pkgs,
  ...
}: {
  imports = [
    "${nhModules}/common"
    "${nhModules}/desktop/hyprland"
  ];

  # Enable home-manager
  programs.home-manager = {
    enable = true;
  };

  # Essential packages for this machine
  home.packages = with pkgs; [
    bitwarden # Password manager
    google-chrome # Web browser
    nodejs_20 # Node.js runtime
    nixos-anywhere # Remote NixOS deployment tool
    # spotify                           # Moved to Flatpak for better Wayland support
    thunderbird # Email client
  ];

  # Stop the CLI's auto-updater; Nix will handle upgrades.
  home.sessionVariables.DISABLE_AUTOUPDATER = "1";

  # Enable shortcuts viewer with custom shortcuts
  programs.shortcuts-viewer = {
    enable = true;
    keybinding = "Super+slash";
    theme = "catppuccin-macchiato";
    interface = "rofi";
    
    # Add some custom shortcuts for testing
    shortcuts = {
      hyprland = {
        applications = [
          { key = "Super+Shift+Return"; action = "Open Ghostty terminal"; icon = ""; }
          { key = "Super+Shift+F"; action = "Open file manager"; icon = ""; }
          { key = "Ctrl+Space"; action = "Toggle Albert launcher"; icon = ""; }
        ];
        window_management = [
          { key = "Super+Q"; action = "Close active window"; icon = ""; }
          { key = "Super+F"; action = "Toggle floating window"; icon = ""; }
          { key = "Super+M"; action = "Toggle fullscreen"; icon = ""; }
        ];
        workspaces = [
          { key = "Super+1-9"; action = "Switch to workspace 1-9"; icon = ""; }
          { key = "Super+Shift+1-9"; action = "Move window to workspace 1-9"; icon = ""; }
        ];
      };
      
      tmux = {
        core = [
          { key = "Ctrl+Q"; action = "Tmux prefix key"; icon = ""; }
          { key = "Prefix+R"; action = "Reload tmux config"; icon = ""; }
        ];
        panes = [
          { key = "Prefix+v"; action = "Split pane vertically"; icon = ""; }
          { key = "Prefix+s"; action = "Split pane horizontally"; icon = ""; }
        ];
      };
      
      neovim = {
        files = [
          { key = "Space+ff"; action = "Find files with Telescope"; icon = ""; }
          { key = "Ctrl+P"; action = "Find git files"; icon = ""; }
          { key = "Space+w"; action = "Save file"; icon = ""; }
        ];
        lsp = [
          { key = "K"; action = "Show hover information"; icon = ""; }
          { key = "Space+ca"; action = "Code actions"; icon = ""; }
          { key = "Space+rn"; action = "Rename symbol"; icon = ""; }
        ];
      };
    };
    
    # Disable auto-detection for now
    autoDetect.enable = false;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/chrome" = ["chromium-browser.desktop"];
      "x-scheme-handler/ftp" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "application/pdf" = "firefox.desktop";
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
