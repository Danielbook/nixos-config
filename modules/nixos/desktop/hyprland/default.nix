{pkgs, ...}: {
  # Enable GDM display manager
  services.displayManager.gdm.enable = true;

  # Call dbus-update-activation-environment on login
  services.xserver.updateDbusEnvironment = true;

  # Enable Bluetooth support
  services.blueman.enable = true;

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
  };

  # Enable security services
  security.polkit.enable = true;
  security.pam.services = {
    hyprlock = {};
  };

  # List of Hyprland specific packages
  environment.systemPackages = with pkgs; [
    file-roller # archive manager
    gnome-calculator
    gnome-pomodoro
    gnome-text-editor
    loupe # image viewer
    nautilus # file manager
    totem # Video player

    brightnessctl
    grim
    hypridle
    hyprlock
    hyprpaper
    swww
    hyprpicker
    libnotify
    networkmanagerapplet
    pamixer
    pavucontrol
    slurp
    wf-recorder
    wlr-randr
    wlsunset
  ];
}
