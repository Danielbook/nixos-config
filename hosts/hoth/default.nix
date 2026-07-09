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
  # ADR-0002, hoth's host key is pre-generated on the admin machine and injected
  # at install (nixos-anywhere --extra-files), so &hoth is already a recipient in
  # .sops.yaml and secrets.yaml decrypts on first boot — no post-install re-key.
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  # k3s: 3rd control-plane (F2) — brings etcd to 3-member HA quorum. apiVip is
  # set so hoth's apiserver cert gets --tls-san=.5 — needed for the VIP to fail
  # over onto hoth without TLS errors. vipInterface left unset: kube-vip
  # auto-detects hoth's default-route NIC.
  homelab.k3s = {
    enable = true;
    role = "server";
    serverAddr = "https://10.10.40.5:6443";
    apiVip = "10.10.40.5";
    nodeIp = "10.10.40.11"; # pin the real IP — see homelab.k3s.nodeIp doc
  };

  # MetalLB L2 LoadBalancer — managed by the Argo `metallb` app (k8s/infra/metallb.yaml).
  # The Nix module stays in-tree but disabled; do not re-enable (both managing it would race).

  # Argo CD + ksops GitOps controller (see services/argocd). Root app tracks
  # k8s/infra. One-time: seed the `sops-age` secret out-of-band (ADR 0001).
  homelab.argocd.enable = true;

  system.stateVersion = "25.05";
}
