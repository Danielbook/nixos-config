# Role, IP and the shared node config come from the cluster inventory
# (modules/nixos/services/k3s/nodes.nix and cluster-node.nix).
{ nixosModules, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    "${nixosModules}/services/k3s/cluster-node.nix"
  ];

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
