{
  inputs,
  nhModules,
  pkgs,
  ...
}:
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/programs/aerospace"
    "${nhModules}/programs/alacritty"
    "${nhModules}/programs/brave"
    "${nhModules}/programs/firefox"
    "${nhModules}/programs/ghostty"
    "${nhModules}/programs/kitty"
    "${nhModules}/programs/vscode"
  ];

  programs.home-manager.enable = true;

  home.packages = [
    inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.bitwarden-cli
    pkgs.k9s # Terminal UI for the k3s cluster (kubeconfig at ~/.kube/config)
  ];

  # Catpuccin flavor and accent
  catppuccin = {
    flavor = "macchiato";
    accent = "lavender";
  };

  home.stateVersion = "25.05";
}
