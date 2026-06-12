{
  pkgs,
  lib,
  ...
}:
# nixpkgs brave is Linux-only → install via homebrew cask on darwin.
lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
  home.packages = with pkgs; [
    brave
  ];
}
