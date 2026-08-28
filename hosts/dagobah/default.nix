{
  hostname,
  darwinModules,
  ...
}:
{
  imports = [
    "${darwinModules}/common"
  ];

  networking.hostName = hostname;

  # Apple Silicon MacBook Pro
  nixpkgs.hostPlatform = "aarch64-darwin";

  # TrueNAS photos dataset, same share as coruscant's /mnt/photos. Reachable
  # on the LAN or over the home-vpn WireGuard tunnel; the export authorizes
  # both, and `resvport` is required — macOS doesn't use a reserved source
  # port by default, Linux does. macOS root is read-only, so it lands under
  # $HOME. autofs (automountd runs as root) mounts on first access and
  # unmounts when idle — no reachability watcher needed, macOS doesn't block
  # on a dead map the way autofs_wait does.
  environment.etc."auto_nfs".text = ''
    /Users/daniel/mnt/photos -fstype=nfs,resvport,soft,timeo=50,retrans=1,nobrowse 10.10.40.10:/mnt/pool1/media/photos
  '';

  # /etc/auto_master has no include directive — the whole file is replaced, with
  # the stock entries kept verbatim plus the /- direct map above.
  environment.etc."auto_master".text = ''
    #
    # Automounter master map
    #
    +auto_master		# Use directory service
    #/net			-hosts		-nobrowse,hidefromfinder,nosuid
    /home			auto_home	-nobrowse,hidefromfinder
    /Network/Servers	-fstab
    /-			-static
    /-			auto_nfs
  '';

  system.activationScripts.postActivation.text = ''
    /usr/sbin/automount -cv >/dev/null
  '';
}
