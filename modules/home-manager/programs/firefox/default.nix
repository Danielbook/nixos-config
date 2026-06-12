{
  pkgs,
  lib,
  ...
}:
# nixpkgs firefox + firefoxpwa have no darwin build → install Firefox via homebrew
# cask on darwin. This module manages no profile config, so skipping it there loses nothing.
lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    configPath = ".mozilla/firefox";
    nativeMessagingHosts = [
      pkgs.firefoxpwa
    ];
  };

  home.packages = with pkgs; [
    firefoxpwa
  ];
}
