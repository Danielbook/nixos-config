_: {
  # direnv + nix-direnv - automatic Nix dev shell activation
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true; # suppress the `export +VAR...` dump on load
  };
}
