{config, ...}: {
  # Install and configure Golang via home-manager module
  programs.go = {
    enable = true;

    # Use env-based configuration (new API)
    env = {
      GOBIN = "${config.home.homeDirectory}/go/bin";
      GOPATH = "${config.home.homeDirectory}/go";
    };
  };

  # Ensure Go bin in the PATH
  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
  ];
}
