{ config, pkgs, ... }:

{
  # Enable Flakes + Unfree packages (e.g. Chrome)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Hardware-specific config
  imports = [
    ./hardware-configuration.nix

    # Modular components
    ./modules/bluetooth.nix
    ./modules/locale.nix
    ./modules/fonts.nix
    ./modules/shell.nix
    ./modules/gnome.nix
    ./modules/hyprland.nix
    ./modules/nvidia.nix
    ./modules/pipewire.nix
    ./modules/packages.nix
    ./modules/docker.nix
    ./modules/user-daniel.nix
    ./modules/networking.nix
    ./modules/xdg.nix
    ./modules/flatpak.nix
  ];

  services.gvfs.enable = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set this to match your install version
  system.stateVersion = "24.11";
}

