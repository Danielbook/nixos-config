{
  outputs,
  userConfig,
  pkgs,
  ...
}: {
  imports = [
    #    ../programs/tmux
    ../misc/qt
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
    ../programs/lazygit
    ../programs/neovim
    ../programs/starship
    ../programs/tmux
    ../programs/ulauncher
    ../programs/zsh
    ../scripts
    ../services/easyeffects
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

  # ensure common packages are installed
  home.packages = with pkgs; [
    anki-bin
    awscli2
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
    xterm
  ];

  # Catpuccin flavor and accent
  catppuccin = {
    flavor = "macchiato";
    accent = "lavender";
  };
}
