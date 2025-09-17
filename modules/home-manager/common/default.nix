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
    ../programs/lazygit
    ../programs/neovim
    ../programs/obs-studio
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
    anki-bin                      # Flashcard and spaced repetition learning app
    awscli2                       # AWS command line interface v2
    bash                          # Bash shell (fallback/compatibility)
    dig                           # DNS lookup utility
    du-dust                       # Modern disk usage analyzer (du replacement)
    eza                           # Modern ls replacement with colors and icons
    fd                            # Fast find alternative for files/directories
    firefox                       # Mozilla Firefox web browser
    jq                            # JSON processor and formatter
    lazydocker                    # Docker container management TUI
    nh                            # NixOS helper for rebuilding and managing generations
    openconnect                   # Cisco AnyConnect VPN client
    # pavucontrol               # PulseAudio volume control (installed in nixos module)
    pipenv                        # Python virtual environment manager
    prusa-slicer                  # 3D printer slicer for Prusa printers
    python3                       # Python 3 interpreter
    ripgrep                       # Fast grep alternative with better defaults
    terraform                     # Infrastructure as code tool
    tesseract                     # OCR engine for text recognition
    unzip                         # Archive extraction utility
    wl-clipboard                  # Wayland clipboard manager
    xdg-desktop-portal            # Desktop integration portal
    xdg-desktop-portal-hyprland   # Hyprland-specific desktop portal
    xterm                         # X terminal emulator (fallback)
  ];

  # Catpuccin flavor and accent
  catppuccin = {
    flavor = "macchiato";
    accent = "lavender";
  };
}
