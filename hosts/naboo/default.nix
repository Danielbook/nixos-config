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
  homelab.k3s = {
    enable = true;
    role = "server-init";
    # TODO (open item — reserve the .40 IPs first, see docs/CLUSTER.md):
    #   apiVip = "10.10.40.X";   # control-plane VIP (kube.local.bookorjeman.com)
    #   vipInterface = "eno1";   # confirm naboo's NIC name on first boot
  };

  system.stateVersion = "25.05";
}
