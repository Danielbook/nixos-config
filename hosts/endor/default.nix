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
  # ADR-0002, endor's host key is pre-generated on the admin machine and injected
  # at install (nixos-anywhere --extra-files), so &endor is already a recipient in
  # .sops.yaml and secrets.yaml decrypts on first boot — no post-install re-key.
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  # k3s: 2nd control-plane. Joins the embedded-etcd cluster via serverAddr (the
  # API VIP). apiVip is set so endor's apiserver cert gets --tls-san=.5 — needed
  # for the VIP to fail over onto endor without TLS errors. vipInterface is left
  # unset: kube-vip auto-detects endor's default-route NIC (eno1), so the shared
  # DaemonSet works despite naboo being eno2.
  homelab.k3s = {
    enable = true;
    role = "server";
    serverAddr = "https://10.10.40.5:6443";
    apiVip = "10.10.40.5";
    nodeIp = "10.10.40.14"; # pin the real IP — see homelab.k3s.nodeIp doc
  };

  # MetalLB L2 LoadBalancer — ADOPTED INTO GITOPS (Stage E3): now managed by the
  # Argo `metallb` app (k8s/infra/metallb.yaml). The Nix module stays in-tree but
  # disabled; do not re-enable (both managing it would race).

  # Argo CD + ksops GitOps controller (see services/argocd). Root app tracks
  # k8s/infra. One-time: seed the `sops-age` secret out-of-band (ADR 0001).
  homelab.argocd.enable = true;

  system.stateVersion = "25.05";
}
