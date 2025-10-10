{
  outputs,
  userConfig,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ../programs/aerospace
    ../programs/alacritty
    ../programs/atuin
    ../programs/bat
    ../programs/brave
    ../programs/btop
    ../programs/fastfetch
    ../programs/fzf
    ../programs/ghostty
    ../programs/git
    ../programs/go
    ../programs/gpg
    ../programs/jujutsu
    ../programs/lazygit
    ../programs/neovim
    ../programs/ssh
    ../programs/starship
    ../programs/tmux
    ../programs/vscodium
    ../programs/zsh
    ../scripts
    ../misc/wallpaper
  ];

  # Nixpkgs configuration
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
    ];

    config = {
      allowUnfree = true;
    };
  };

  # Home-Manager configuration for the user's home environment
  home = {
    username = userConfig.name;
    homeDirectory = "/Users/${userConfig.name}";
  };

  # Essential user packages for daily workflow (macOS)
  home.packages = with pkgs; [
    # Cross-platform packages
    bash # Bash shell (fallback/compatibility)
    dig # DNS lookup utility
    nodejs_24 # Node.js runtime
    du-dust # Modern disk usage analyzer (du replacement)
    eza # Modern ls replacement with colors and icons
    fd # Fast find alternative for files/directories
    firefox # Mozilla Firefox web browser
    jq # JSON processor and formatter
    lazydocker # Docker container management TUI
    openconnect # Cisco AnyConnect VPN client
    pipenv # Python virtual environment manager
    python3 # Python 3 interpreter
    ripgrep # Fast grep alternative with better defaults
    terraform # Infrastructure as code tool
    claude-code # Claude Code CLI

    # macOS-specific packages
    aerospace # Tiling window manager for macOS
    colima # Container runtimes on macOS with minimal setup
    hidden-bar # Hide menu bar items on macOS
    raycast # Spotlight replacement for macOS
    rectangle # Window management utility for macOS
  ];

  # Catpuccin flavor and accent
  catppuccin = {
    flavor = "macchiato";
    accent = "lavender";
  };

  # Enable Ghostty configuration (works with Homebrew Ghostty)
  programs.ghostty.enableConfig = true;

  # Set wallpaper on Darwin using osascript
  launchd.agents.wallpaper = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/osascript"
        "-e"
        "tell application \"Finder\" to set desktop picture to POSIX file \"${config.wallpaper}\""
      ];
      RunAtLoad = true;
      Label = "wallpaper";
    };
  };
}
