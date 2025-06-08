{nhModules, pkgs, ...}: {
  imports = [
    "${nhModules}/common"
    "${nhModules}/desktop/hyprland"
  ];

  # Enable home-manager
  programs.home-manager = {
    enable = true;
  };

  # ensure common packages are installed
  home.packages = with pkgs;
    [
      bitwarden
      google-chrome
      spotify
      thunderbird
    ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
