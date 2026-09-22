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
    nodeIp = "10.10.40.13"; # pin the real IP — see homelab.k3s.nodeIp doc
  };

  # MetalLB L2 LoadBalancer — ADOPTED INTO GITOPS (Stage E3): now managed by the
  # Argo `metallb` app (k8s/infra/metallb.yaml). The Nix module stays in-tree but
  # disabled; do not re-enable (both managing it would race).

  # Argo CD + ksops GitOps controller (see services/argocd). Root app tracks
  # k8s/infra. One-time: seed the `sops-age` secret out-of-band (ADR 0001).
  homelab.argocd.enable = true;

  # homeassistant-stack (Stage F1c): homeassistant + matter-server run
  # hostNetwork, pinned here. NixOS firewall blocks inbound by default, so the
  # Service ClusterIP -> node-IP:port path (used by Traefik/other nodes) needs
  # these opened explicitly — was a 504 until this landed.
  # 21063 = HA's HomeKit Bridge HAP port (integrations/homekit.yaml, PVC config).
  # mDNS (UDP 5353) was never opened, unlike jupiter's plain host-network Docker
  # box — Apple Home couldn't discover or pair the bridge after the k3s move.
  networking.firewall.allowedTCPPorts = [
    8123 # homeassistant
    21063 # homekit bridge (HAP)
    8095 # music-assistant web/API
    8097 # music-assistant stream server (players pull audio)
  ];
  networking.firewall.allowedUDPPorts = [ 5353 ]; # mDNS/Bonjour for HomeKit discovery
  # music-assistant listens on random ports in the Linux ephemeral range
  # (excludes NodePorts 30000-32767): AirPlay (RAOP) — the Denon (static
  # 192.168.1.60) connects back to cliairplay's timing/control/event ports;
  # Spotify Connect — LAN clients hit soloist's zeroconf HTTP port.
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw -s 192.168.1.60 -p udp --dport 32768:60999 -j nixos-fw-accept
    iptables -I nixos-fw -s 192.168.1.0/24 -p tcp --dport 32768:60999 -j nixos-fw-accept
  '';

  system.stateVersion = "25.05";
}
