# Apps that run with `hostNetwork: true`, pinned to one node by a nodeSelector.
# The NixOS firewall blocks inbound traffic by default, so this file opens the
# ports of each app on its node. Each k8s manifest points back here.
#
# Keep `node` equal to the nodeSelector in the manifest. When an app moves to a
# different node, change both in the same commit.
#
# Per app: node, tcp and udp ports, and optional extra iptables rules.
{ hostname, lib, ... }:
let
  apps = {
    # k8s/apps/homeassistant/homeassistant.yaml. Traefik and other nodes reach
    # it through the Service ClusterIP to node-IP:port path. Without the open
    # port, that path gave a 504.
    homeassistant = {
      node = "naboo";
      tcp = [
        8123 # web UI and API
        21063 # HomeKit Bridge HAP port (integrations/homekit.yaml, PVC config)
      ];
      # mDNS/Bonjour for HomeKit discovery. jupiter was a plain host-network
      # Docker box. After the k3s move, Apple Home could not find or pair the
      # bridge until this port was open.
      udp = [ 5353 ];
    };

    # k8s/apps/homeassistant/matter-server.yaml. No Service and no open ports.
    # Only homeassistant talks to it, on the same node.
    matter-server = {
      node = "naboo";
    };

    # k8s/apps/homeassistant/music-assistant.yaml.
    music-assistant = {
      node = "naboo";
      tcp = [
        8095 # web UI and API
        8097 # stream server (players pull audio)
      ];
      # music-assistant listens on random ports in the Linux ephemeral range
      # (NodePorts 30000-32767 stay outside it). AirPlay (RAOP): the Denon
      # (static 192.168.1.60) connects back to the timing, control and event
      # ports of cliairplay. Spotify Connect: LAN clients reach the zeroconf
      # HTTP port of soloist.
      extraCommands = ''
        iptables -I nixos-fw -s 192.168.1.60 -p udp --dport 32768:60999 -j nixos-fw-accept
        iptables -I nixos-fw -s 192.168.1.0/24 -p tcp --dport 32768:60999 -j nixos-fw-accept
      '';
    };
  };

  onThisNode = lib.filter (app: app.node == hostname) (lib.attrValues apps);
  extraCommands = lib.concatMapStrings (app: app.extraCommands or "") onThisNode;
in
{
  networking.firewall = {
    allowedTCPPorts = lib.concatMap (app: app.tcp or [ ]) onThisNode;
    allowedUDPPorts = lib.concatMap (app: app.udp or [ ]) onThisNode;
    # Only define it when there is a rule. An empty definition adds a blank line.
    extraCommands = lib.mkIf (extraCommands != "") extraCommands;
  };
}
