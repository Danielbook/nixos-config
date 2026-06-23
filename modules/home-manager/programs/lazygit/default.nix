_: {
  # Install lazygit via home-manager module
  programs.lazygit = {
    enable = true;

    settings = {
      git = {
        pagers = [
          {
            colorArg = "always";
            pager = "delta --color-only --dark --paging=never";
          }
        ];
      };

      os = {
        edit = "nvim {{filename}}";
        editAtLine = "nvim +{{line}} {{filename}}";
        editAtLineAndWait = "nvim +{{line}} {{filename}}";
      };
    };
  };

  # Enable Catppuccin theme for Lazygit
  catppuccin.lazygit.enable = true;
}
