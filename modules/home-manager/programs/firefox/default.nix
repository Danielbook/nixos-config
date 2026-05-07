{pkgs, ...}: {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    configPath = ".mozilla/firefox";
    nativeMessagingHosts = [
      pkgs.firefoxpwa
    ];
  };

  home.packages = with pkgs; [
    firefoxpwa
  ];
}