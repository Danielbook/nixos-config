{
  config,
  inputs,
  lib,
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
    inputs.sops-nix.homeManagerModules.sops
  ];

  # Fetch Age private key from Bitwarden before sops decrypts
  # Requires: `bw login && export BW_SESSION=$(bw unlock --raw)` before running HM switch
  home.activation.fetchAgeKey = lib.hm.dag.entryBefore [ "sops-nix" ] ''
    mkdir -p ${config.home.homeDirectory}/.config/sops/age
    if command -v bw >/dev/null 2>&1; then
      if ! bw unlock --check >/dev/null 2>&1; then
        echo "WARNING: Bitwarden is locked — skipping Age key fetch. Run: export BW_SESSION=\$(bw unlock --raw)"
      else
        KEY=$(bw get notes "SOPS_AGE_KEY" 2>/dev/null) || true
        if [ -n "$KEY" ]; then
          echo "$KEY" > ${config.home.homeDirectory}/.config/sops/age/keys.txt
          chmod 600 ${config.home.homeDirectory}/.config/sops/age/keys.txt
        fi
      fi
    fi
  '';

  # Secrets management with sops-nix
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets.authentik_mcp_token = { };
  };

  # Source sops secrets as environment variables in the shell
  programs.zsh.initContent = lib.mkOrder 1200 ''
    export AUTHENTIK_MCP_TOKEN="$(cat ${config.sops.secrets.authentik_mcp_token.path} 2>/dev/null)"
  '';

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
