{...}: {
  # Enable OpenGL for Intel integrated graphics only
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Use Intel graphics driver only (no NVIDIA)
  services.xserver.videoDrivers = ["modesetting"];

  # Disable NVIDIA GPU entirely to improve suspend/resume and battery life
  boot.extraModprobeConfig = ''
    # Disable NVIDIA GPU
    blacklist nvidia
    blacklist nvidia_drm
    blacklist nvidia_modeset
    blacklist nouveau
    # Keep Intel graphics working
    options i915 modeset=1
  '';

  # Power management: disable NVIDIA GPU completely
  boot.blacklistedKernelModules = ["nvidia" "nvidia_drm" "nvidia_modeset" "nouveau"];
}
