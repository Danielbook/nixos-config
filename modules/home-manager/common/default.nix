{
  userConfig,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../programs/atuin
    ../programs/bat
    ../programs/btop
    ../programs/carapace
    ../programs/direnv
    ../programs/fastfetch
    ../programs/fzf
    ../programs/gh
    ../programs/git

    ../programs/gpg
    ../programs/jujutsu
    ../programs/lazygit
    ../programs/neovim
    ../programs/agents
    ../programs/sesh
    ../programs/ssh
    ../programs/starship
    ../programs/tmux
    ../programs/yazi
    ../programs/zoxide
    ../programs/zsh
    ../scripts
  ];

  # Nicely reload system units when changing configs (Linux only)
  systemd.user.startServices = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "sd-switch";

  # Home-Manager configuration for the user's home environment
  home = {
    username = userConfig.name;
    homeDirectory =
      if pkgs.stdenv.hostPlatform.isDarwin then
        "/Users/${userConfig.name}"
      else
        "/home/${userConfig.name}";
  };

  # Essential CLI packages
  home.packages =
    (with pkgs; [
      bash
      bruno
      bun
      dig
      dust
      eza
      fd
      github-copilot-cli
      glab
      jq
      lazydocker
      nodejs_24
      openconnect
      ripgrep
      television
      unzip
      uv
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.nh
    ];

  # Catpuccin flavor and accent
  catppuccin = {
    enable = true;
    autoEnable = false; # only the ports enabled explicitly per-program
    flavor = "macchiato";
    accent = "lavender";
  };
}
