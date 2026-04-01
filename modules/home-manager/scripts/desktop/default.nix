{...}: {
  # Desktop-specific scripts (Hyprland/Wayland)
  home.file = {
    ".local/bin/hyprshot" = {
      source = ../desktop-bin/hyprshot;
      executable = true;
    };
    ".local/bin/ocr" = {
      source = ../desktop-bin/ocr;
      executable = true;
    };
    ".local/bin/screen-recorder" = {
      source = ../desktop-bin/screen-recorder;
      executable = true;
    };
    ".local/bin/waybar-restart" = {
      source = ../desktop-bin/waybar-restart;
      executable = true;
    };
  };
}
