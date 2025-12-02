{
  inputs,
  nhModules,
  pkgs,
  ...
}: {
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

  # Essential packages for this machine
  home.packages = with pkgs; [
    bitwarden-desktop # Password manager
    google-chrome # Web browser
    nodejs_24 # Node.js runtime
    nixos-anywhere # Remote NixOS deployment tool
    # spotify                           # Moved to Flatpak for better Wayland support
    thunderbird # Email client
    inputs.hyprdynamicmonitors.packages.${pkgs.stdenv.hostPlatform.system}.default # Monitor configuration tool
    inputs.hypr-binds.packages.${pkgs.stdenv.hostPlatform.system}.default # Hyprland keybindings viewer
  ];

  # Secrets management with sops-nix
  sops = {
    age.keyFile = "/home/daniel/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
  };

  # Stop the CLI's auto-updater; Nix will handle upgrades.
  home.sessionVariables.DISABLE_AUTOUPDATER = "1";

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
