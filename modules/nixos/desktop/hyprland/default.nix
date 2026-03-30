{pkgs, ...}: {
  # Enable greetd display manager with tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd 'exec dbus-run-session Hyprland'";
        user = "greeter";
      };
    };
  };

  # Ensure greetd has proper environment
  environment.etc."greetd/environments".text = ''
    Hyprland
  '';

  # Call dbus-update-activation-environment on login
  services.xserver.updateDbusEnvironment = true;

  # Enable Bluetooth support
  services.blueman.enable = true;

  # Enable GVFS for mounting remote filesystems (SMB, FTP, etc.)
  services.gvfs.enable = true;

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
  };

  # Enable security services
  security.polkit.enable = true;
  # List of Hyprland specific packages
  environment.systemPackages = with pkgs; [
    file-roller # archive manager
    gnome-calculator
    gnome-text-editor
    loupe # image viewer
    nautilus # file manager
    totem # Video player

    brightnessctl
    grim
    hyprpicker
    libnotify
    networkmanagerapplet
    # pamixer # Temporarily disabled due to build issues
    pavucontrol
    slurp
    wf-recorder
    wlr-randr
    wlsunset
  ];
}
