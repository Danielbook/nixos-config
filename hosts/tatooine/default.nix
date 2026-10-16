# Role, IP and the shared node config come from the cluster inventory
# (modules/nixos/services/k3s/nodes.nix and cluster-node.nix).
{ nixosModules, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    "${nixosModules}/services/k3s/cluster-node.nix"
    "${nixosModules}/services/nvidia-headless"
  ];

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
