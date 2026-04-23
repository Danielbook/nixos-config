{
  config,
  pkgs,
  ...
}: {
  # Intel iGPU + NVIDIA RTX 3060 Mobile (GA106) — PRIME Sync.
  # dGPU drives HDMI and all rendering; iGPU stays present for KMS handoff.
  # VA-API drivers for both GPUs so libva can auto-pick per app.
  # Firefox/Chrome render on Intel (via Mesa EGL) → need intel-media-driver.
  # Native NVIDIA apps (mpv, Darktable) use nvidia-vaapi-driver.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [
      pkgs.nvidia-vaapi-driver
      pkgs.intel-media-driver
    ];
    extraPackages32 = [
      pkgs.pkgsi686Linux.nvidia-vaapi-driver
      pkgs.pkgsi686Linux.intel-media-driver
    ];
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

  # GBM/GLX pinned to NVIDIA so Hyprland renders on the dGPU under PRIME Sync.
  # LIBVA_DRIVER_NAME deliberately NOT set: forcing it to nvidia breaks VA-API
  # for browsers that render on the Intel iGPU (Chrome/Firefox use Mesa EGL,
  # not NVIDIA EGL, so nvidia-vaapi-driver fails to init). With it unset, libva
  # auto-picks iHD for Intel-context apps and nvidia for NVIDIA-context apps.
  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    VDPAU_DRIVER = "va_gl";
  };
}
