{pkgs, ...}: {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    nativeMessagingHosts = [
      pkgs.firefoxpwa
    ];
  };

  home.packages = with pkgs; [
    firefoxpwa
  ];
}