{pkgs, ...}: {
  home.packages = with pkgs; [
    obs-studio
    ffmpeg
    pipewire
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    wl-clipboard

    # Optional OBS plugins
    obs-studio-plugins.wlrobs
    obs-studio-plugins.obs-vkcapture
    obs-studio-plugins.obs-pipewire-audio-capture
    v4l-utils
  ];

  home.sessionVariables = {
    # Wayland and desktop compatibility
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
  };
}
