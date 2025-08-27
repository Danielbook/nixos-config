{
  outputs,
  userConfig,
  pkgs,
  ...
}: {
  imports = [
    ../misc/qt
    ../misc/sshfs
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

  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
  ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Home-Manager configuration for the user's home environment
  home = {
    username = "${userConfig.name}";
    homeDirectory = "/home/${userConfig.name}";
  };

  # ensure common packages are installed
  home.packages = with pkgs; [
    anki-bin
    awscli2
    bash
    dig
    du-dust
    eza
    fd
    firefox
    jq
    lazydocker
    nh
    openconnect
    pavucontrol
    pipenv
    python3
    ripgrep
    terraform
    tesseract
    unzip
    wl-clipboard
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xterm
  ];

  # Catpuccin flavor and accent
  catppuccin = {
    flavor = "macchiato";
    accent = "lavender";
  };
}
