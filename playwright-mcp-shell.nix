{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = [
    pkgs.nodejs_22
    pkgs.gnugrep
    pkgs.coreutils
    # Playwright browser dependencies
    pkgs.glib
    pkgs.nss
    pkgs.nspr
    pkgs.dbus
    pkgs.atk
    pkgs.at-spi2-atk
    pkgs.cups
    pkgs.expat
    pkgs.xorg.libxcb
    pkgs.libxkbcommon
    pkgs.xorg.libX11
    pkgs.xorg.libXcomposite
    pkgs.xorg.libXdamage
    pkgs.xorg.libXext
    pkgs.xorg.libXfixes
    pkgs.xorg.libXrandr
    pkgs.mesa
    pkgs.pango
    pkgs.cairo
    pkgs.udev
    pkgs.alsa-lib
    # Playwright driver with browsers
    pkgs.playwright-driver.browsers
  ];

  shellHook = ''
    # Set library paths for Playwright browser dependencies
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      pkgs.glib
      pkgs.nss
      pkgs.nspr
      pkgs.dbus
      pkgs.atk
      pkgs.at-spi2-atk
      pkgs.cups
      pkgs.expat
      pkgs.xorg.libxcb
      pkgs.libxkbcommon
      pkgs.xorg.libX11
      pkgs.xorg.libXcomposite
      pkgs.xorg.libXdamage
      pkgs.xorg.libXext
      pkgs.xorg.libXfixes
      pkgs.xorg.libXrandr
      pkgs.mesa
      pkgs.pango
      pkgs.cairo
      pkgs.udev
      pkgs.alsa-lib
    ]}:$LD_LIBRARY_PATH"

    # Configure Playwright to use Nix-provided browsers
    export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true

    # Set writable user data directory
    export PLAYWRIGHT_CHROMIUM_USER_DATA_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/playwright-mcp"
    mkdir -p "$PLAYWRIGHT_CHROMIUM_USER_DATA_DIR"
  '';
}
