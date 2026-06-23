{
  pkgs,
  lib,
  ...
}:
# AeroSpace tiling WM — darwin only. Mirrors the coruscant Hyprland keybinds,
# but uses `alt` (Option) as the modifier instead of SUPER/Cmd: on macOS Cmd is
# reserved by apps (Cmd+W/F/Space/1-9/M), so binding the WM to it clobbers them.
# Key LAYOUT matches Hyprland; only the modifier differs.
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  programs.aerospace = {
    enable = true;
    # Let Home Manager manage the launchd agent; `start-at-login` is overridden accordingly.
    launchd.enable = true;
    settings = {
      start-at-login = true;

      # Tiling defaults
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      # Gaps (Hyprland-ish spacing)
      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.left = 8;
        outer.right = 8;
        outer.top = 8;
        outer.bottom = 8;
      };

      # Assign apps to workspaces — mirrors Hyprland windowrule workspace=N
      on-window-detected = [
        {
          "if".app-id = "com.mitchellh.ghostty";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "org.mozilla.firefox";
          run = "move-node-to-workspace 2";
        }
        {
          "if".app-id = "com.brave.Browser";
          run = "move-node-to-workspace 2";
        }
        {
          "if".app-id = "com.google.Chrome";
          run = "move-node-to-workspace 2";
        }
        {
          "if".app-id = "com.microsoft.teams2";
          run = "move-node-to-workspace 3";
        }
        {
          "if".app-id = "com.microsoft.Outlook";
          run = "move-node-to-workspace 3";
        }
        {
          "if".app-id = "com.spotify.client";
          run = "move-node-to-workspace 4";
        }
      ];

      mode.main.binding = {
        # --- Applications (Hyprland: mod+Return terminal, mod+E files, mod+B browser) ---
        alt-enter = "exec-and-forget open -na Ghostty";
        alt-e = "exec-and-forget open -a Finder";
        alt-b = "exec-and-forget open -a 'Brave Browser'";
        # Hyprland mod+Y/mod+A/mod+shift+G open chrome PWAs; on macOS ChatGPT and
        # WhatsApp ship as native apps (Homebrew casks), YouTube Music stays a PWA.
        alt-y = "exec-and-forget open -na 'Google Chrome' --args --app=https://music.youtube.com";
        alt-a = "exec-and-forget open -a ChatGPT";
        alt-shift-g = "exec-and-forget open -a WhatsApp";
        # Launcher: macOS Spotlight is already Cmd-Space natively (kept Hyprland's mod+Space intent).
        # Swap to Raycast if installed: "exec-and-forget open -a Raycast".

        # --- Window actions (Hyprland: W close, F float, M fullscreen, O orientation) ---
        alt-w = "close";
        alt-f = "layout floating tiling";
        alt-m = "fullscreen";
        alt-o = "layout tiles horizontal vertical";
        alt-shift-enter = "layout tiles horizontal vertical"; # approx of swapwithmaster

        # --- Focus (Hyprland: mod+hjkl) ---
        alt-h = "focus left";
        alt-l = "focus right";
        alt-k = "focus up";
        alt-j = "focus down";

        # --- Move window (mac addition; Hyprland moved via mouse drag) ---
        alt-shift-h = "move left";
        alt-shift-l = "move right";
        alt-shift-k = "move up";
        alt-shift-j = "move down";

        # --- Resize (Hyprland: mod+shift+arrows) ---
        alt-shift-left = "resize width -50";
        alt-shift-right = "resize width +50";
        alt-shift-up = "resize height -50";
        alt-shift-down = "resize height +50";

        # --- Workspaces 1-0 (Hyprland: 0 = workspace 10) ---
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-0 = "workspace 10";

        # --- Move to workspace (Hyprland: mod+shift+N) ---
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
        alt-shift-0 = "move-node-to-workspace 10";

        # --- Workspace cycle (Hyprland: mod+scroll) ---
        alt-tab = "workspace-back-and-forth";

        # --- Screenshot (Hyprland: mod+shift+S region, mod+ctrl+S window) ---
        alt-shift-s = "exec-and-forget screencapture -i -c"; # region → clipboard
        alt-ctrl-s = "exec-and-forget screencapture -iW -c"; # window → clipboard

        # --- Lock screen (Hyprland: ctrl+alt+L) ---
        # Sends the native macOS lock shortcut (Ctrl+Cmd+Q) via System Events;
        # reliably shows the login window. `pmset displaysleepnow` and the old
        # CGSession path don't lock on modern macOS. AeroSpace already holds
        # Accessibility permission (for window management), so keystrokes work.
        ctrl-alt-l = "exec-and-forget osascript -e 'tell application \"System Events\" to keystroke \"q\" using {control down, command down}'";

        # --- Reload config (Hyprland: ctrl+alt+Q exit) ---
        ctrl-alt-q = "reload-config";
      };
    };
  };
}
