{
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (pkgs.stdenv.isDarwin) {
    # Ensure aerospace package installed
    home.packages = [pkgs.aerospace];

    # AeroSpace configuration file
    home.file.".aerospace.toml".text = ''
      # Start AeroSpace at login
      start-at-login = true

      # Normalization settings
      enable-normalization-flatten-containers = true
      enable-normalization-opposite-orientation-for-nested-containers = true

      # Accordion layout settings
      accordion-padding = 30

      # Default root container settings
      default-root-container-layout = 'tiles'
      default-root-container-orientation = 'auto'

      # Mouse follows focus settings
      on-focused-monitor-changed = ['move-mouse monitor-lazy-center']
      on-focus-changed = ['move-mouse window-lazy-center']

      # Automatically unhide macOS hidden apps
      automatically-unhide-macos-hidden-apps = true

      # Key mapping preset
      [key-mapping]
      preset = 'qwerty'

      # Gaps settings
      [gaps]
      inner.horizontal = 8
      inner.vertical =   8
      outer.left =       8
      outer.bottom =     8
      outer.top =        8
      outer.right =      8

      # Main mode bindings
      [mode.main.binding]
      # Launch applications
      alt-shift-enter = 'exec-and-forget open -na ghostty'
      alt-shift-b = 'exec-and-forget open -a "Firefox"'
      alt-shift-c = 'exec-and-forget open -a "Visual Studio Code"'
      alt-shift-f = 'exec-and-forget open -a Finder'
      alt-shift-s = 'exec-and-forget open -a "Spotify"'
      alt-shift-d = 'exec-and-forget open -a "Discord"'

      # Window management
      alt-q = "close"
      alt-m = 'fullscreen'
      alt-f = 'layout floating tiling'

      # Focus movement (vim-style)
      alt-h = 'focus left'
      alt-j = 'focus down'
      alt-k = 'focus up'
      alt-l = 'focus right'

      # Window movement
      alt-shift-h = 'move left'
      alt-shift-j = 'move down'
      alt-shift-k = 'move up'
      alt-shift-l = 'move right'

      # Resize windows
      alt-shift-minus = 'resize smart -50'
      alt-shift-equal = 'resize smart +50'

      # Workspace management (9 workspaces)
      alt-1 = 'workspace 1'
      alt-2 = 'workspace 2'
      alt-3 = 'workspace 3'
      alt-4 = 'workspace 4'
      alt-5 = 'workspace 5'
      alt-6 = 'workspace 6'
      alt-7 = 'workspace 7'
      alt-8 = 'workspace 8'
      alt-9 = 'workspace 9'

      # Move windows to workspaces
      alt-shift-1 = 'move-node-to-workspace --focus-follows-window 1'
      alt-shift-2 = 'move-node-to-workspace --focus-follows-window 2'
      alt-shift-3 = 'move-node-to-workspace --focus-follows-window 3'
      alt-shift-4 = 'move-node-to-workspace --focus-follows-window 4'
      alt-shift-5 = 'move-node-to-workspace --focus-follows-window 5'
      alt-shift-6 = 'move-node-to-workspace --focus-follows-window 6'
      alt-shift-7 = 'move-node-to-workspace --focus-follows-window 7'
      alt-shift-8 = 'move-node-to-workspace --focus-follows-window 8'
      alt-shift-9 = 'move-node-to-workspace --focus-follows-window 9'

      # Workspace navigation
      alt-tab = 'workspace-back-and-forth'
      alt-shift-tab = 'move-workspace-to-monitor --wrap-around next'

      # Enter passthrough mode for typing special characters
      alt-p = 'mode passthrough'

      # Enter service mode
      alt-shift-semicolon = 'mode service'

      # Service mode bindings
      [mode.service.binding]
      # Reload config and exit service mode
      esc = ['reload-config', 'mode main']

      # Reset layout
      r = ['flatten-workspace-tree', 'mode main']

      # Toggle floating/tiling layout
      f = ['layout floating tiling', 'mode main']

      # Close all windows but current
      backspace = ['close-all-windows-but-current', 'mode main']

      # Join with adjacent windows
      alt-shift-h = ['join-with left', 'mode main']
      alt-shift-j = ['join-with down', 'mode main']
      alt-shift-k = ['join-with up', 'mode main']
      alt-shift-l = ['join-with right', 'mode main']

      # Passthrough mode to allow typing special characters
      # Enter with 'alt-p', exit with 'alt-p' or 'esc'
      [mode.passthrough.binding]
      alt-p = 'mode main'
      esc = 'mode main'

      # Window detection rules for automatic workspace assignment
      [[on-window-detected]]
      if.app-id = 'org.mozilla.firefox'
      run = 'move-node-to-workspace 1'

      [[on-window-detected]]
      if.app-id = 'com.mitchellh.ghostty'
      run = 'move-node-to-workspace 2'

      [[on-window-detected]]
      if.app-id = 'com.microsoft.VSCode'
      run = 'move-node-to-workspace 3'

      [[on-window-detected]]
      if.app-id = 'com.spotify.client'
      run = 'move-node-to-workspace 4'

      [[on-window-detected]]
      if.app-id = 'com.hnc.Discord'
      run = 'move-node-to-workspace 5'

      [[on-window-detected]]
      if.app-id = 'com.1password.1password'
      run = 'move-node-to-workspace 6'

      [[on-window-detected]]
      if.app-id = 'md.obsidian'
      run = 'move-node-to-workspace 7'
    '';
  };
}