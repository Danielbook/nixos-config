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

  # k3s: GPU worker (agent), joins via the API VIP. No metallb/argocd imports —
  # only control-plane nodes run the k3s addon-manifest controller, so those
  # modules would be inert here.
  homelab.k3s = {
    enable = true;
    role = "agent";
    nodeIp = "10.10.40.15"; # pin the real IP — see homelab.k3s.nodeIp doc
  };

  # GPU node scheduling (Stage D1): taint keeps non-GPU pods off the box
  # (jellyfin/immich carry the matching toleration); the label is what the
  # NVIDIA device plugin DaemonSet selects on (k8s/infra/nvidia-plugin.yaml).
  # Applied by kubelet at agent registration — no imperative kubectl taint.
  services.k3s.extraFlags = [
    "--node-taint=nvidia.com/gpu=present:NoSchedule"
    "--node-label=nvidia.com/gpu.present=true"
  ];

  system.stateVersion = "25.05";
}
