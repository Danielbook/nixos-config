# Shared config for every k3s cluster node in nodes.nix. The host file adds
# only hardware, disko and node-specific settings.
#
# Role and node IP come from the inventory. Control-plane roles also import
# control-plane.nix.
{
  hostname,
  inputs,
  lib,
  nixosModules,
  ...
}:
let
  node = (import ./nodes.nix).${hostname};
in
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    "${nixosModules}/common"
    "${nixosModules}/services/k3s"
    ./host-network-apps.nix
  ]
  ++ lib.optional (node.role != "agent") ./control-plane.nix;

  networking.hostName = hostname;

  # System secrets (sops-nix). Decrypted at boot via the host SSH key. Per
  # ADR-0002, the host key is pre-generated on the admin machine and injected at
  # install (nixos-anywhere --extra-files). Thus the node is already a recipient
  # in .sops.yaml and secrets.yaml decrypts on first boot without a re-key.
  sops = {
    defaultSopsFile = ../../../../hosts/${hostname}/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  homelab.k3s = {
    enable = true;
    inherit (node) role;
    nodeIp = node.ip; # pin the real IP, see ADR-0006
  };
}
