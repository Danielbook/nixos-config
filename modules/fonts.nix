{ config, pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      font-awesome

      # You can pick your patched Nerd Fonts here:
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "Hack" ]; })
    ];
  };
}

