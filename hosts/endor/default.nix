# Role, IP and the shared node config come from the cluster inventory
# (modules/nixos/services/k3s/nodes.nix and cluster-node.nix).
{ nixosModules, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    "${nixosModules}/services/k3s/cluster-node.nix"
  ];

  system.stateVersion = "25.05";
}
