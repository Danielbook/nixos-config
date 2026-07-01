# MetalLB (L2/ARP mode) — the cluster's only service LoadBalancer (k3s servicelb
# is disabled in services/k3s). Deployed via k3s auto-deploy manifests, mirroring
# the kube-vip pattern. Transitional: Argo adopts k8s/infra/metallb at Stage B5.
#
# Two manifests: the pinned upstream native manifest (CRDs + controller + speaker
# + validating webhook), then the address-pool CRs. The pool CRs reference the
# CRDs and are gated by the webhook, so the first apply pass can fail — the k3s
# addon controller re-enqueues until CRDs + webhook are up.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.metallb;

  # Pinned upstream native manifest. Bump the tag + rehash (nix store
  # prefetch-file <url>) to upgrade.
  metallbManifest = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml";
    hash = "sha256-vyX+67dYLKffhF79Uv+8KWDWy/TPyXL0f97Z94i2fws=";
  };

  # Address pool (.50–.60, reserved outside the Kea dynamic pool .100–.250) +
  # L2Advertisement. interfaces is left UNSET on purpose: MetalLB auto-announces
  # on the NIC owning the route to each service IP — pinning one crashes the odd
  # node out (naboo eno2 / endor eno1), same lesson as kube-vip's vipInterface.
  metallbPoolManifest = pkgs.writeText "metallb-pool.yaml" ''
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: lan-pool
      namespace: metallb-system
    spec:
      addresses:
        - 10.10.40.50-10.10.40.60
    ---
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: lan-l2
      namespace: metallb-system
    spec:
      ipAddressPools:
        - lan-pool
  '';
in
{
  options.homelab.metallb.enable = lib.mkEnableOption "MetalLB service LoadBalancer (L2 mode)";

  config = lib.mkIf cfg.enable {
    services.k3s.manifests = {
      metallb-native.source = metallbManifest;
      metallb-pool.source = metallbPoolManifest;
    };
  };
}
