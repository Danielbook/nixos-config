{
  config,
  hostname,
  inputs,
  nixosModules,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
    "${nixosModules}/common"
    "${nixosModules}/desktop/common"
    "${nixosModules}/desktop/hyprland"
    "${nixosModules}/services/tlp"
    "${nixosModules}/services/usb-serial"
    "${nixosModules}/services/audio-lowlatency"
    "${nixosModules}/graphics"
    "${nixosModules}/memory-protection"
  ];

  # Set hostname
  networking.hostName = hostname;

  # System-level secrets (sops-nix). Decrypted at boot using the host SSH key,
  # so no Bitwarden/interactive unlock is needed during activation. The secrets
  # file is encrypted to both the host key and daniel's personal age key (see
  # .sops.yaml) — the personal key is the durable recovery path if the machine
  # is reinstalled and the host key changes.
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # WireGuard client private key for the home-vpn tunnel.
    secrets.wg_home_private_key = { };

    # Render the NetworkManager keyfile with the private key injected, straight
    # into NM's system-connections dir. NM picks it up automatically. Endpoint is
    # the DDNS hostname (vpn.bookorjeman.com) so it survives WAN IP changes — see
    # docs/WIREGUARD.md. autoconnect is off: toggle from the tray / nmcli as before.
    templates."home-vpn.nmconnection" = {
      path = "/etc/NetworkManager/system-connections/home-vpn.nmconnection";
      mode = "0600";
      owner = "root";
      group = "root";
      content = ''
        [connection]
        id=home-vpn
        uuid=86a92a95-13a9-4424-9320-de30e2dbda45
        type=wireguard
        interface-name=home-vpn
        autoconnect=false

        [wireguard]
        private-key=${config.sops.placeholder.wg_home_private_key}

        [wireguard-peer.iV0MNbpADdaf7Y1zjN0AWv/7UscT/TKOVN52N7o6UW0=]
        endpoint=vpn.bookorjeman.com:51820
        allowed-ips=0.0.0.0/0;::/0
        persistent-keepalive=25

        [ipv4]
        method=manual
        address1=10.11.11.6/32
        dns=10.11.11.1;

        [ipv6]
        method=disabled
      '';
    };
  };

  # Enable aarch64 emulation for cross-compilation
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # NFS client support (for TrueNAS media share over WireGuard)
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;

  # TrueNAS photos dataset, accessed over the home-vpn WireGuard tunnel.
  # Reachability-gated automount: a watcher polls NFS port 2049 and only
  # starts the automount unit when the NAS is reachable. Without this,
  # stat()s on /mnt/photos block ~30-40s on autofs_wait when the NAS is
  # offline (file managers, zoxide, fzf all hang).
  systemd.mounts = [
    {
      what = "10.10.40.10:/mnt/pool1/media/photos";
      where = "/mnt/photos";
      type = "nfs";
      options = "soft,timeo=50,retrans=1,_netdev";
      mountConfig.TimeoutSec = "5s";
    }
  ];

  systemd.automounts = [
    {
      where = "/mnt/photos";
      automountConfig.TimeoutIdleSec = "600";
      # Do NOT auto-enable at boot — the watcher controls activation.
      wantedBy = lib.mkForce [ ];
    }
  ];

  systemd.services.nas-photos-watcher = {
    description = "Toggle /mnt/photos automount based on NAS reachability";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nas-photos-check" ''
        if ${pkgs.netcat-openbsd}/bin/nc -z -w 1 10.10.40.10 2049 2>/dev/null; then
          ${pkgs.systemd}/bin/systemctl start mnt-photos.automount
        else
          ${pkgs.systemd}/bin/systemctl stop mnt-photos.automount 2>/dev/null || true
        fi
      '';
    };
  };

  systemd.timers.nas-photos-watcher = {
    description = "Periodic NAS reachability probe for /mnt/photos";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "20s";
      OnUnitActiveSec = "60s";
      Unit = "nas-photos-watcher.service";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
