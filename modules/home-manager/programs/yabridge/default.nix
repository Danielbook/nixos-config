{
  lib,
  pkgs,
  config,
  ...
}:
{
  # Wine + yabridge for running Windows VST plugins (Neural DSP, etc.)
  # Carla as standalone plugin host for jamming

  home.packages = with pkgs; [
    wineWow64Packages.stagingFull # 32+64bit Wine with staging patches (esync/fsync)
    yabridge # VST bridge: runs Windows VST plugins in Linux hosts
    yabridgectl # CLI tool to manage yabridge plugin directories
    carla # Modular audio plugin host (standalone + rack mode)
  ];

  # Wine performance variables for audio workloads
  home.sessionVariables = {
    WINEESYNC = "1"; # Eventfd-based synchronization (lower overhead)
    WINEFSYNC = "1"; # Futex-based synchronization (even faster, kernel 5.16+)
    WINEDEBUG = "-all"; # Suppress Wine debug output for lower latency
  };

  # yabridgectl configuration pointing to standard Wine VST directories
  xdg.configFile."yabridgectl/config.toml".text = ''
    plugin_dirs = [
      "${config.home.homeDirectory}/.wine/drive_c/Program Files/Common Files/VST2",
      "${config.home.homeDirectory}/.wine/drive_c/Program Files/Common Files/VST3",
    ]
  '';

  # Sync yabridge on activation (only if plugin dirs exist)
  home.activation.yabridgeSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "${config.home.homeDirectory}/.wine/drive_c/Program Files/Common Files/VST3" ] || \
       [ -d "${config.home.homeDirectory}/.wine/drive_c/Program Files/Common Files/VST2" ]; then
      ${pkgs.yabridgectl}/bin/yabridgectl sync 2>/dev/null || true
    fi
  '';
}
