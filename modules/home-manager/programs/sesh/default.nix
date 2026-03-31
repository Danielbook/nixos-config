{pkgs, ...}: {
  home.packages = [pkgs.sesh];

  xdg.configFile."sesh/sesh.toml".source = ./sesh.toml;
}
