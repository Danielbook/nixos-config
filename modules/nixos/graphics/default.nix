{
  config,
  pkgs,
  ...
}: {
  # Intel iGPU + NVIDIA RTX 3060 Mobile (GA106) — PRIME Sync.
  # dGPU drives HDMI and all rendering; iGPU stays present for KMS handoff.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [pkgs.nvidia-vaapi-driver];
    extraPackages32 = [pkgs.pkgsi686Linux.nvidia-vaapi-driver];
  };

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    prime = {
      sync.enable = true;
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:1@0:0:0";
    };
  };

  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    VDPAU_DRIVER = "va_gl";
  };
}
