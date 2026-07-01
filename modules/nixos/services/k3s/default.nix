# k3s cluster node — role-parameterized wrapper around services.k3s.
#
# Roles:
#   server-init : first control-plane node, initialises the embedded-etcd cluster.
#   server      : additional control-plane node, joins via the API VIP.
#   agent       : worker node (e.g. the GPU box, tatooine).
#
# The shared cluster token comes from the host's sops secrets.yaml. kube-vip is
# auto-deployed on control-plane nodes once `apiVip` is set (it stays inert until
# the .40 VIP is reserved — see docs/cluster-implementation.md).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.k3s;
  isServer = cfg.role != "agent";

  # kube-vip control-plane manifest (ARP / L2 mode). k3s auto-applies anything in
  # /var/lib/rancher/k3s/server/manifests/. Only rendered when apiVip is set.
  kubeVipManifest = pkgs.writeText "kube-vip.yaml" ''
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: kube-vip
      namespace: kube-system
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: system:kube-vip-role
    rules:
      - apiGroups: [""]
        resources: ["services", "services/status", "nodes", "endpoints"]
        verbs: ["list", "get", "watch", "update"]
      - apiGroups: ["coordination.k8s.io"]
        resources: ["leases"]
        verbs: ["list", "get", "watch", "update", "create"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: system:kube-vip-binding
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: system:kube-vip-role
    subjects:
      - kind: ServiceAccount
        name: kube-vip
        namespace: kube-system
    ---
    apiVersion: apps/v1
    kind: DaemonSet
    metadata:
      name: kube-vip-ds
      namespace: kube-system
    spec:
      selector:
        matchLabels:
          name: kube-vip-ds
      template:
        metadata:
          labels:
            name: kube-vip-ds
        spec:
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                  - matchExpressions:
                      - key: node-role.kubernetes.io/control-plane
                        operator: Exists
          containers:
            - name: kube-vip
              image: ghcr.io/kube-vip/kube-vip:v0.8.4
              args: ["manager"]
              env:
                - { name: vip_arp, value: "true" }
                - { name: port, value: "6443" }
                - { name: vip_interface, value: "${cfg.vipInterface}" }
                - { name: vip_cidr, value: "32" }
                - { name: cp_enable, value: "true" }
                - { name: cp_namespace, value: "kube-system" }
                - { name: svc_enable, value: "false" }
                - { name: vip_leaderelection, value: "true" }
                - { name: address, value: "${cfg.apiVip}" }
              securityContext:
                capabilities:
                  add: ["NET_ADMIN", "NET_RAW"]
              imagePullPolicy: IfNotPresent
          hostNetwork: true
          serviceAccountName: kube-vip
          tolerations:
            - { effect: NoSchedule, operator: Exists }
            - { effect: NoExecute, operator: Exists }
  '';
in
{
  options.homelab.k3s = {
    enable = lib.mkEnableOption "k3s cluster node";

    role = lib.mkOption {
      type = lib.types.enum [
        "server-init"
        "server"
        "agent"
      ];
      description = "server-init = first control-plane (etcd init); server = joining control-plane; agent = worker.";
    };

    apiVip = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "10.10.40.5";
      description = "Control-plane VIP (kube-vip, servers only). Empty = kube-vip disabled until the .40 IP is reserved.";
    };

    vipInterface = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "eno1";
      description = "LAN NIC kube-vip ARP-announces the VIP on. Empty (default) = auto-detect the default-route NIC per node — required when cluster nodes have different NIC names (naboo eno2 / endor eno1). Set explicitly only to override a wrong auto-detect.";
    };

    serverAddr = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "https://10.10.40.5:6443";
      description = "API endpoint joining nodes register against (the VIP). Required for role server/agent.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open k3s ports on the host firewall. OPNsense restricts inter-VLAN reach (see docs/cluster-implementation.md).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Joining nodes must know the API endpoint (the VIP) to register against.
    assertions = [
      {
        assertion = cfg.role == "server-init" || cfg.serverAddr != "";
        message = "homelab.k3s.serverAddr is required for role \"${cfg.role}\" (only server-init may omit it).";
      }
    ];

    # Shared cluster token — provided by the host's sops secrets.yaml.
    sops.secrets.k3s_token = { };

    services.k3s = {
      enable = true;
      role = if cfg.role == "agent" then "agent" else "server";
      tokenFile = config.sops.secrets.k3s_token.path;
      clusterInit = cfg.role == "server-init";
      serverAddr = lib.mkIf (cfg.role != "server-init") cfg.serverAddr;
      extraFlags =
        lib.optionals isServer [
          "--disable=traefik"
          "--disable=servicelb"
        ]
        ++ lib.optionals (isServer && cfg.apiVip != "") [
          "--tls-san=${cfg.apiVip}"
        ];
      manifests = lib.mkIf (isServer && cfg.apiVip != "") {
        kube-vip.source = kubeVipManifest;
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        10250
      ]
      ++ lib.optionals isServer [
        6443
        2379
        2380
      ];
      allowedUDPPorts = [ 8472 ]; # flannel vxlan
    };
  };
}
