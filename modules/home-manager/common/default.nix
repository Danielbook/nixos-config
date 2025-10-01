{
  outputs,
  userConfig,
  pkgs,
  ...
}: {
  imports = [
    ../programs/alacritty
    ../programs/albert
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
    ../programs/obs-studio
    ../programs/ssh
    ../programs/starship
    ../programs/tmux
    ../programs/vscodium
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
    username = "${userConfig.name}";
    homeDirectory = "/home/${userConfig.name}";
  };

  # Essential user packages for daily workflow
  home.packages = with pkgs; [
    # Flashcard and spaced repetition learning app
    anki-bin
    # AWS command line interface v2
    awscli2
    # Bash shell (fallback/compatibility)
    bash
    # DNS lookup utility
    dig
    # Modern disk usage analyzer (du replacement)
    du-dust
    # Modern ls replacement with colors and icons
    eza
    # Fast find alternative for files/directories
    fd
    # Mozilla Firefox web browser
    firefox
    # JSON processor and formatter
    jq
    # Docker container management TUI
    lazydocker
    # NixOS helper for rebuilding and managing generations
    nh
    # Cisco AnyConnect VPN client
    openconnect
    # Python virtual environment manager
    pipenv
    # 3D printer slicer for Prusa printers
    prusa-slicer
    # Python 3 interpreter
    python3
    # Fast grep alternative with better defaults
    ripgrep
    # Infrastructure as code tool
    terraform
    # OCR engine for text recognition
    tesseract
    # Wayland wallpaper daemon
    swww
    # Archive extraction utility
    unzip
    # Wayland clipboard manager
    wl-clipboard
    # Desktop integration portal
    xdg-desktop-portal
    # Hyprland-specific desktop portal
    xdg-desktop-portal-hyprland
    # X terminal emulator (fallback)
    xterm
  ];

  # Catpuccin flavor and accent
  catppuccin = {
    flavor = "macchiato";
    accent = "lavender";
  };
}
