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
    "${nixosModules}/services/metallb"
    "${nixosModules}/services/argocd"
  ];

  networking.hostName = hostname;

  # System secrets (sops-nix). Decrypted at boot via the host SSH key. Per
  # ADR-0002, naboo's host key is pre-generated on the admin machine and injected
  # at install (nixos-anywhere --extra-files), so &naboo is already a recipient in
  # .sops.yaml and secrets.yaml decrypts on first boot — no post-install re-key.
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  # k3s: bootstrap control-plane (first server, initialises embedded etcd).
  # kube-vip advertises the API VIP (.5). vipInterface is left unset so kube-vip
  # auto-detects the default-route NIC per node — required because the cluster-wide
  # DaemonSet spans nodes with different NIC names (naboo eno2 / endor eno1).
  homelab.k3s = {
    enable = true;
    role = "server-init";
    apiVip = "10.10.40.5"; # control-plane VIP (kube.local.bookorjeman.com)
    nodeIp = "10.10.40.13"; # pin the real IP — see homelab.k3s.nodeIp doc
  };

  # MetalLB L2 LoadBalancer — ADOPTED INTO GITOPS (Stage E3): now managed by the
  # Argo `metallb` app (k8s/infra/metallb.yaml). The Nix module stays in-tree but
  # disabled; do not re-enable (both managing it would race).

  # Argo CD + ksops GitOps controller (see services/argocd). Root app tracks
  # k8s/infra. One-time: seed the `sops-age` secret out-of-band (ADR 0001).
  homelab.argocd.enable = true;

  system.stateVersion = "25.05";
}
