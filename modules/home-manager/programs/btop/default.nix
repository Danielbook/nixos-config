_: {
  # Install btop via home-manager module
  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
    };
  };

  xdg.configFile."btop/btop.conf".force = true;
}
