{
  inputs,
  nhModules,
  pkgs,
  ...
}: {
  imports = [
    "${nhModules}/common"
    "${nhModules}/programs/alacritty"
    "${nhModules}/programs/brave"
    "${nhModules}/programs/firefox"
    "${nhModules}/programs/ghostty"
    "${nhModules}/programs/kitty"
    "${nhModules}/programs/vscode"
    inputs.sops-nix.homeManagerModules.sops
  ];

  programs.home-manager.enable = true;

  home.packages = [
    inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Secrets management
  sops = {
    age.keyFile = "/Users/daniel/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
  };

  # Catpuccin flavor and accent
  catppuccin = {
    flavor = "macchiato";
    accent = "lavender";
  };

  home.stateVersion = "25.05";
}
