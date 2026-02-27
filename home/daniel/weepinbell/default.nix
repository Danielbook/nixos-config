{
  config,
  inputs,
  lib,
  nhModules,
  pkgs,
  ...
}: let
  noctaliaConfigDir = ./noctalia;
in {
  imports = [
    "${nhModules}/common"
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
    feishin # Navidrome/Subsonic music player
    # google-chrome # Installed via programs.chromium below with custom flags
    nodejs_24 # Node.js runtime
    nixos-anywhere # Remote NixOS deployment tool
    pgadmin4-desktopmode # PostgreSQL administration tool
    # spotify - installed by spicetify-nix module
    thunderbird # Email client
    inputs.hyprdynamicmonitors.packages.${pkgs.stdenv.hostPlatform.system}.default # Monitor configuration tool
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default # Zen browser (Firefox-based)
  ];

  # Secrets management with sops-nix
  sops = {
    age.keyFile = "/home/daniel/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
  };

  # Stop the CLI's auto-updater; Nix will handle upgrades.
  home.sessionVariables.DISABLE_AUTOUPDATER = "1";

  # Configure Chrome/Chromium with touchpad gesture support
  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome;
    commandLineArgs = [
      "--enable-features=TouchpadOverscrollHistoryNavigation"
    ];
  };

  # HyprDynamicMonitors - manual configuration management
  # Disable the built-in module to use custom config files
  # home.hyprdynamicmonitors = {
  #   enable = true;
  #   extraFlags = ["--disable-power-events"];
  # };

  # HyprDynamicMonitors configuration files (managed manually)
  xdg.configFile."hyprdynamicmonitors/config.toml".source = ./hyprdynamicmonitors/config.toml;
  xdg.configFile."hyprdynamicmonitors/hyprconfigs/home.go.tmpl".source = ./hyprdynamicmonitors/hyprconfigs/home.go.tmpl;
  xdg.configFile."hyprdynamicmonitors/hyprconfigs/work.go.tmpl".source = ./hyprdynamicmonitors/hyprconfigs/work.go.tmpl;
  xdg.configFile."hyprdynamicmonitors/hyprconfigs/laptop.go.tmpl".source = ./hyprdynamicmonitors/hyprconfigs/laptop.go.tmpl;

  # Manual systemd service for hyprdynamicmonitors
  systemd.user.services.hyprdynamicmonitors = {
    Unit = {
      Description = "HyprDynamicMonitors - automatic monitor configuration";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${inputs.hyprdynamicmonitors.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/hyprdynamicmonitors --disable-power-events";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  # Spicetify - Spotify theming (integrated with Noctalia)
  programs.spicetify = let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in {
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
  home.activation.noctaliaConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/.config/noctalia
    cp -f ${noctaliaConfigDir}/settings.json ${config.home.homeDirectory}/.config/noctalia/
    cp -f ${noctaliaConfigDir}/user-templates.toml ${config.home.homeDirectory}/.config/noctalia/
    cp -f ${noctaliaConfigDir}/plugins.json ${config.home.homeDirectory}/.config/noctalia/
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/chrome" = ["chromium-browser.desktop"];
      "x-scheme-handler/ftp" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "application/pdf" = "firefox.desktop";
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
