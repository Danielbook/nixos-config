{
  hostname,
  inputs,
  nixosModules,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
    "${nixosModules}/common"
    "${nixosModules}/services/k3s"
  ];

  networking.hostName = hostname;

  # System secrets (sops-nix). Decrypted at boot via the host SSH key. The
  # secrets file is currently encrypted to daniel only (recovery) — after the
  # first install, capture naboo's host age key (`ssh-to-age` on its host pubkey),
  # add it to .sops.yaml as &naboo, then: sops updatekeys hosts/naboo/secrets.yaml
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
