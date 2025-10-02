{
  config,
  lib,
  ...
}: {
  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # helpful for Steam/Wine & some Electron bits on NVIDIA
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Disabled due to suspend/resume issues - use systemd configuration instead
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.production;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Verify these PCI bus IDs with: lspci | grep -E "(VGA|3D)"
      intelBusId = "PCI:0:2:0";  # Verify this matches your Intel iGPU
      nvidiaBusId = "PCI:1:0:0"; # Verify this matches your NVIDIA GPU
    };
  };

  # Systemd configuration for better suspend/resume with NVIDIA
  systemd.services."systemd-suspend" = {
    serviceConfig = {
      Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
    };
  };

  # NVIDIA-specific kernel module configuration for suspend/resume
  boot.extraModprobeConfig = ''
    # NVIDIA suspend/resume support - simplified for compatibility
    options nvidia_modeset vblank_sem_control=0
  '';

  # Power management resume commands for NVIDIA
  powerManagement.resumeCommands = ''
    # Reload NVIDIA modules after resume
    ${lib.getBin config.boot.kernelPackages.nvidia_x11}/bin/nvidia-smi || true
  '';
}
