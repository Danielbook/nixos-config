{
  inputs,
  outputs,
  lib,
  config,
  userConfig,
  pkgs,
  ...
}: {
  # Import common server configuration
  imports = [
    "${inputs.self}/modules/nixos/common"
  ];

  # Override desktop-specific settings from common
  # Disable X server components
  services.xserver.enable = lib.mkForce false;

  # Essential server packages only
  environment.systemPackages = lib.mkForce (with pkgs; [
    # Core system utilities
    bash # Ensure bash is available for system scripts
    zsh # Z shell for better user experience
    util-linux # Mount, umount, and other essential system utilities
    killall # Process termination utility
    htop # Interactive process viewer
    iotop # I/O monitoring tool
    ncdu # Disk usage analyzer
    rsync # File synchronization tool
    wget # HTTP/FTP download utility
    curl # Data transfer tool with URL syntax
    vim # Text editor
    neovim # Modern Vim-based editor
    tmux # Terminal multiplexer
    git # Version control system
    fuse3 # Filesystem in userspace (for mounting)
  ]);

  # Remove desktop fonts, keep minimal set
  fonts.packages = lib.mkForce (with pkgs; [
    dejavu_fonts # Basic font for any GUI tools
  ]);

  # Disable Bluetooth for servers
  hardware.bluetooth.enable = lib.mkForce false;

  # Disable Flatpak for headless servers
  services.flatpak.enable = lib.mkForce false;

  # Enable neovim as default editor system-wide
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Remove desktop-specific environment variables but keep essential ones
  environment.variables = lib.mkForce {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Disable Plymouth boot splash for faster boot
  boot.plymouth.enable = lib.mkForce false;

  # Server-optimized kernel parameters
  boot.kernelParams = [
    "quiet"
    "rd.udev.log_level=3"
    # Server performance tuning
    "transparent_hugepage=madvise"
  ];

  # Enhanced SSH configuration for servers
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
    openFirewall = true;
  };

  # Server-specific systemd services
  systemd.services = {
    # Disable unnecessary services for headless operation
    NetworkManager-wait-online.enable = lib.mkForce false;
  };

  # Basic firewall configuration - specific ports defined per host
  networking.firewall = {
    enable = true;
    # Only SSH open by default for headless servers
    # Individual hosts should define their specific service ports
  };

  # Server monitoring and maintenance
  services.logrotate.enable = true;

  # Automatic system maintenance
  system.autoUpgrade = {
    enable = false; # Disable for now, enable manually
    dates = "weekly";
    allowReboot = false;
  };

  # Ensure /srv directory exists with correct permissions
  system.activationScripts.srv-directory = ''
    mkdir -p /srv
    chown ${userConfig.name}:users /srv
    chmod 755 /srv
  '';
}
