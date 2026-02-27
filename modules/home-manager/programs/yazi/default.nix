{...}: {
  # Install yazi via home-manager module
  programs.yazi = {
    enable = true;
    enableZshIntegration = true; # Adds 'y' wrapper command for better navigation
    shellWrapperName = "y";

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
      };

      preview = {
        max_width = 1000;
        max_height = 1000;
        image_filter = "lanczos3";
        image_quality = 90;
      };

      opener = {
        edit = [
          {
            run = ''nvim "$@"'';
            block = true;
          }
        ];
      };
    };
  };

  # Enable catppuccin theming for yazi
  catppuccin.yazi.enable = true;
}
