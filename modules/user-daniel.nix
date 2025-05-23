{ config, pkgs, ... }:
{
  users.users.daniel = {
    isNormalUser = true;
    description = "Daniel Böök";
    extraGroups = [ "networkmanager" "wheel" "docker" "input" ];
    shell = pkgs.zsh;
  };

  services.xserver.autoRepeatDelay = 200;  # Delay in ms before repeat starts
  services.xserver.autoRepeatInterval = 25; # Time between repeats
}
