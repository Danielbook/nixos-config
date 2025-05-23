{ config, pkgs, ... }:

{
  # Enable X server just enough for Hyprland
  services.xserver.enable = true;

  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  # Use a simple display manager — or disable if you want to use TTY
  services.displayManager.sddm.enable = true;
  
  # Hyprland Wayland compositor
  programs.hyprland = {
    enable = true; 
    xwayland.enable = true;
  };

  programs.hyprlock.enable = true;

  security.pam.services.hyprlock = {};
}

