{
  hostname,
  inputs,
  nixosModules,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    "${nixosModules}/common"
    "${nixosModules}/services/k3s"
    "${nixosModules}/services/nvidia-headless"
    "${nixosModules}/services/metallb"
    "${nixosModules}/services/argocd"
  ];

  networking.hostName = hostname;

  # System secrets (sops-nix). Decrypted at boot via the host SSH key. Per
  # ADR-0002, tatooine's host key is pre-generated on the admin machine and
  # injected at install (nixos-anywhere --extra-files), so &tatooine is already
  # a recipient in .sops.yaml and secrets.yaml decrypts on first boot — no
  # post-install re-key.
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  # k3s: GPU worker (agent), joins via the API VIP. metallb/argocd are
  # imported for parity with naboo/endor but left disabled below — only
  # control-plane nodes run the k3s addon-manifest controller that would use
  # them, so enabling here would be inert.
  homelab.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://10.10.40.5:6443";
  };

  system.stateVersion = "25.05";
}
