{...}: {
  # direnv + nix-direnv - automatic Nix dev shell activation
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
