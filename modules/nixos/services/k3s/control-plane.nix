# Shared config for k3s control-plane nodes (role server-init or server).
# cluster-node.nix imports it from the role in nodes.nix. Agents do not
# import it, because only control-plane nodes run the k3s addon-manifest
# controller.
#
# kube-vip advertises the API VIP. vipInterface stays unset, so kube-vip finds
# the default-route NIC on each node (naboo eno2, endor eno1).
{ nixosModules, ... }:
{
  imports = [
    "${nixosModules}/services/metallb"
    "${nixosModules}/services/argocd"
  ];

  # MetalLB L2 LoadBalancer: the Argo `metallb` app manages it now
  # (k8s/infra/metallb.yaml, Stage E3). The Nix module stays in-tree but
  # disabled. Do not enable it again, because two managers would race.

  # Argo CD + ksops GitOps controller (see services/argocd). Root app tracks
  # k8s/infra. One-time: seed the `sops-age` secret out-of-band (ADR 0001).
  homelab.argocd.enable = true;
}
