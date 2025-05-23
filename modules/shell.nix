{ config, pkgs, ... }:
{
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;
  programs.zsh.ohMyZsh.enable = true;
}
