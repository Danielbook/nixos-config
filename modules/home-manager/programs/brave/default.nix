{
  pkgs,
  lib,
  ...
}: {
  # Ensure Brave browser package installed
  home.packages = with pkgs; [
    brave
  ];
}
