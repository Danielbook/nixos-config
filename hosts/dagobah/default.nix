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
  # macOS updates restore the stock file; let activation overwrite it.
  environment.etc."auto_master".knownSha256Hashes = [
    "b2aac03248e8f229c703561f5bb059f9be491e5db9f447692398d775a9fb12a5"
  ];

  system.activationScripts.postActivation.text = ''
    /usr/sbin/automount -cv >/dev/null
  '';
}
