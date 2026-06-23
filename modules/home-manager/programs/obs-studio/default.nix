{ pkgs, ... }:
{
  home.packages = with pkgs; [
    obs-studio
    ffmpeg

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
  };
}
