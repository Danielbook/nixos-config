{
  inputs,
  hostname,
  nixosModules,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    "${nixosModules}/common"
    "${nixosModules}/desktop/hyprland"
    "${nixosModules}/services/tlp"
    #"${nixosModules}/services/nvidia"
    #"${nixosModules}/programs/steam"
  ];

  # Set hostname
  networking.hostName = hostname;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Load nvidia driver for Xorg and Wayland
  #  services.xserver.videoDrivers = ["nvidia"];
  #
  #hardware.nvidia = {
  #  # Modesetting is required.
  #  modesetting.enable = true;
  #
  #  # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
  #  # Enable this if you have graphical corruption issues or application crashes after waking
  #  # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
  #  # of just the bare essentials.
  #  powerManagement.enable = false;
  #
  #  # Fine-grained power management. Turns off GPU when not in use.
  #  # Experimental and only works on modern Nvidia GPUs (Turing or newer).
  #  powerManagement.finegrained = false;
  #
  #  # Use the NVidia open source kernel module (not to be confused with the
  #  # independent third-party "nouveau" open source driver).
  #  # Support is limited to the Turing and later architectures. Full list of 
  #  # supported GPUs is at: 
  #  # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
  #  # Only available from driver 515.43.04+
  #  open = false;
  #
  #  # Enable the Nvidia settings menu,
  #  # accessible via `nvidia-settings`.
  #  nvidiaSettings = true;
  #
  #  # Optionally, you may need to select the appropriate driver version for your specific GPU.
  #  package = config.boot.kernelPackages.nvidiaPackages.stable;
  #  
  #  prime = {
  #    offload.enable = true;
  #    intelBusId = "PCI:0:2:0";
  #    nvidiaBusId = "PCI:1:0:0";
  #};

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}
