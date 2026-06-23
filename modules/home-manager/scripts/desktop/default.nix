{...}: {
  # Desktop-specific scripts (Hyprland/Wayland)
  home.file = {
    ".local/bin/ocr" = {
      source = ../desktop-bin/ocr;
      executable = true;
    };
    ".local/bin/screen-recorder" = {
      source = ../desktop-bin/screen-recorder;
      executable = true;
    };
  };
}
