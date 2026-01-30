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

  # Alternative: Use gtkgreet for a GUI login
  # Uncomment the following to use gtkgreet instead of tuigreet:
  # services.greetd.settings.default_session.command = "${pkgs.gtkgreet}/bin/gtkgreet -l -c Hyprland";

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
  security.pam.services = {
    # Noctalia lock screen uses its own PAM config
  };

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
    hypridle
    hyprpaper
    hyprpicker
    libnotify
    networkmanagerapplet
    # pamixer # Temporarily disabled due to build issues
    pavucontrol
    wireplumber # Audio session manager
    slurp
    wf-recorder
    wlr-randr
    wlsunset
  ];
}
