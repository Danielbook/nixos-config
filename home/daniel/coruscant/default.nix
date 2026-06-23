{
  config,
  inputs,
  lib,
  nhModules,
  pkgs,
  ...
}:
let
  noctaliaConfigDir = ./noctalia;
in
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/desktop/common"
    "${nhModules}/desktop/hyprland"
    inputs.sops-nix.homeManagerModules.sops
    # hyprdynamicmonitors - managed via TUI in ~/.config/hyprdynamicmonitors/
  ];

  # Enable home-manager
  programs.home-manager = {
    enable = true;
  };

  # Enable Noctalia dynamic theming for tmux
  programs.tmux.noctaliaTheme = true;

  # Essential packages for this machine
  home.packages = with pkgs; [
    bitwarden-desktop # Password manager
    darktable # Open-source photo editor (Lightroom alternative)
    feishin # Navidrome/Subsonic music player
    # google-chrome # Installed via programs.chromium below with custom flags
    nixos-anywhere # Remote NixOS deployment tool
    pgadmin4-desktopmode # PostgreSQL administration tool
    # spotify - installed by spicetify-nix module
    figma-linux # Unofficial Figma desktop client for Linux
    localsend # Local file sharing
    thunderbird # Email client
    inputs.hyprdynamicmonitors.packages.${pkgs.stdenv.hostPlatform.system}.default # Monitor configuration tool
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default # Zen browser (Firefox-based)
    inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.default # Git worktree management CLI
  ];

  # Fetch Age private key from Bitwarden before sops decrypts
  # Requires: `bw login && export BW_SESSION=$(bw unlock --raw)` before running HM switch
  home.activation.fetchAgeKey = lib.hm.dag.entryBefore [ "sops-nix" ] ''
    mkdir -p ${config.home.homeDirectory}/.config/sops/age
    if command -v bw >/dev/null 2>&1; then
      if ! bw unlock --check >/dev/null 2>&1; then
        echo "WARNING: Bitwarden is locked — skipping Age key fetch. Run: export BW_SESSION=\$(bw unlock --raw)"
      else
        KEY=$(bw get notes "SOPS_AGE_KEY" 2>/dev/null) || true
        if [ -n "$KEY" ]; then
          echo "$KEY" > ${config.home.homeDirectory}/.config/sops/age/keys.txt
          chmod 600 ${config.home.homeDirectory}/.config/sops/age/keys.txt
        fi
      fi
    fi
  '';

  # Secrets management with sops-nix
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets.testiny_api_key = { };
  };

  # Stop the CLI's auto-updater; Nix will handle upgrades.
  home.sessionVariables.DISABLE_AUTOUPDATER = "1";

  # Source sops secrets as environment variables in the shell
  programs.zsh.initContent = lib.mkOrder 1200 ''
    export TESTINY_API_KEY="$(cat ${config.sops.secrets.testiny_api_key.path} 2>/dev/null)"
  '';

  # Configure Chrome/Chromium with touchpad gesture support + Intel HW video decode.
  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome;
    commandLineArgs = [
      "--enable-features=TouchpadOverscrollHistoryNavigation,VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxGL,VaapiVideoEncoder"
      "--disable-features=AudioServiceSandbox"
      "--ignore-gpu-blocklist"
    ];
  };

  # HyprDynamicMonitors configuration files (managed manually)
  xdg.configFile."hyprdynamicmonitors/config.toml".source = ./hyprdynamicmonitors/config.toml;
  xdg.configFile."hyprdynamicmonitors/hyprconfigs/home.go.tmpl".source =
    ./hyprdynamicmonitors/hyprconfigs/home.go.tmpl;
  xdg.configFile."hyprdynamicmonitors/hyprconfigs/work.go.tmpl".source =
    ./hyprdynamicmonitors/hyprconfigs/work.go.tmpl;
  xdg.configFile."hyprdynamicmonitors/hyprconfigs/laptop.go.tmpl".source =
    ./hyprdynamicmonitors/hyprconfigs/laptop.go.tmpl;

  # Manual systemd service for hyprdynamicmonitors
  systemd.user.services.hyprdynamicmonitors = {
    Unit = {
      Description = "HyprDynamicMonitors - automatic monitor configuration";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${
        inputs.hyprdynamicmonitors.packages.${pkgs.stdenv.hostPlatform.system}.default
      }/bin/hyprdynamicmonitors --disable-power-events";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Spicetify - Spotify theming (integrated with Noctalia)
  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle
      ];
      theme = spicePkgs.themes.comfy;
    };

  # Noctalia config - copied (not symlinked) so UI can still edit
  # Run `just noctalia-sync` to save changes back to the repo
  home.activation.noctaliaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/.config/noctalia
    cp -f ${noctaliaConfigDir}/settings.json ${config.home.homeDirectory}/.config/noctalia/
    cp -f ${noctaliaConfigDir}/user-templates.toml ${config.home.homeDirectory}/.config/noctalia/
    cp -f ${noctaliaConfigDir}/plugins.json ${config.home.homeDirectory}/.config/noctalia/
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/x-extension-htm" = "google-chrome.desktop";
      "application/x-extension-html" = "google-chrome.desktop";
      "application/x-extension-shtml" = "google-chrome.desktop";
      "application/x-extension-xht" = "google-chrome.desktop";
      "application/x-extension-xhtml" = "google-chrome.desktop";
      "application/xhtml+xml" = "google-chrome.desktop";
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/chrome" = "google-chrome.desktop";
      "x-scheme-handler/ftp" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
      "application/pdf" = "google-chrome.desktop";
      "x-scheme-handler/figma" = "figma-linux.desktop";
    };
  };

  # Fix Figma Linux login: add URI scheme handler so browser auth can call back
  xdg.desktopEntries.figma-linux = {
    name = "Figma Linux";
    comment = "Unofficial Figma desktop application for Linux";
    exec = "figma-linux %U";
    icon = "figma-linux";
    terminal = false;
    type = "Application";
    mimeType = [ "x-scheme-handler/figma" ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
