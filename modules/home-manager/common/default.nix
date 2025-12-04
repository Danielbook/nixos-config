{
  outputs,
  userConfig,
  pkgs,
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
    ../programs/firefox
    ../programs/fuzzel
    ../programs/fzf
    ../programs/ghostty
    ../programs/git
    ../programs/go
    ../programs/gpg
    ../programs/jujutsu
    ../programs/kitty
    ../programs/lazygit
    ../programs/neovim
    ../programs/obs-studio
    ../programs/ssh
    ../programs/starship
    ../programs/tmux
    ../programs/vscode
    # ../programs/vscodium
    ../programs/yazi
    ../programs/zoxide
    ../programs/zsh
    ../scripts
    ../services/easyeffects
    ../services/flatpak
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Home-Manager configuration for the user's home environment
  home = {
    username = userConfig.name;
    homeDirectory = "/home/${userConfig.name}";
  };

  # Essential user packages for daily workflow (Linux)
  home.packages = with pkgs; [
    # Cross-platform packages
    bash # Bash shell (fallback/compatibility)
    dig # DNS lookup utility
    dust # Modern disk usage analyzer (du replacement)
    eza # Modern ls replacement with colors and icons
    fd # Fast find alternative for files/directories
    github-copilot-cli # GitHub Copilot CLI
    jq # JSON processor and formatter
    lazydocker # Docker container management TUI
    nh # NixOS helper for rebuilding and managing generations
    openconnect # Cisco AnyConnect VPN client
    pipenv # Python virtual environment manager
    python3 # Python 3 interpreter
    ripgrep # Fast grep alternative with better defaults
    terraform # Infrastructure as code tool
    unzip # Archive extraction utility
    claude-code # Claude Code editor

    # Linux-specific packages
    # google-chrome # Moved to host-specific config with custom flags
    prusa-slicer # 3D printer slicer for Prusa printers
    satty # Modern Wayland screenshot annotation tool (replaces swappy)
    awww # Wayland wallpaper daemon
    tesseract # OCR engine for text recognition
    wl-clipboard # Wayland clipboard manager
    xdg-desktop-portal # Desktop integration portal
    xdg-desktop-portal-hyprland # Hyprland-specific desktop portal
    xterm # X terminal emulator (fallback)
  ];

  # Catpuccin flavor and accent
  catppuccin = {
    flavor = "macchiato";
    accent = "lavender";
  };
}
