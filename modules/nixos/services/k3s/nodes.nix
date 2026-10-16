# k3s cluster node inventory. This file is the single source of truth for the
# name, IP and role of each node.
#
# Readers: flake.nix makes one nixosConfiguration per entry. cluster-node.nix
# sets homelab.k3s role and nodeIp from it. The justfile reads the IPs and the
# deploy order.
#
# Roles: server-init = bootstrap control-plane, server = joining control-plane,
# agent = worker. Every node gets an explicit --node-ip from `ip` (ADR-0006).
# Host keys and .sops.yaml recipients stay manual (ADR-0002).
{
  # Lenovo M80q. Bootstrap control-plane, initialises the embedded etcd.
  naboo = {
    ip = "10.10.40.13";
    role = "server-init";
  };

  # Lenovo M70q. 2nd control-plane, joins the etcd of naboo via the API VIP.
  endor = {
    ip = "10.10.40.14";
    role = "server";
  };

  # HP EliteDesk 800 G2 Mini. 3rd control-plane (F2) for 3-member etcd HA.
  # Formerly "jupiter", a Docker box.
  hoth = {
    ip = "10.10.40.11";
    role = "server";
  };

  # Bare-metal GPU agent (GTX 1070), Stage D. See ADR-0003.
  tatooine = {
    ip = "10.10.40.15";
    role = "agent";
  };
}
