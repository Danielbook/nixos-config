_: {
  # Source scripts from the home-manager store
  home.file = {
    ".local/bin" = {
      recursive = true;
      source = ./bin;
    };
  };

  # Add ~/.local/bin to PATH for all systems
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
