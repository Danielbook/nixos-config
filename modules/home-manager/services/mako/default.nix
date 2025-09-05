{
  config,
  pkgs,
  ...
}: {
  # For testing with `notify-send`
  home.packages = with pkgs; [
    libnotify
  ];

  # Mako notification daemon
  services.mako = {
    enable = true;
    extraConfig = ''
      # --- Look & feel ---
      font=JetBrains Mono 11
      # Catppuccin-ish "Mocha" vibe
      background-color=#1e1e2e
      text-color=#cdd6f4
      border-color=#89b4fa
      border-size=2
      border-radius=8
      padding=10
      margin=8

      # --- Behavior ---
      default-timeout=5000
      max-visible=5
      layer=overlay
      anchor=top-right
      icons=1

      # Urgency-specific tweaks
      [urgency=low]
      background-color=#313244
      border-color=#74c7ec

      [urgency=normal]
      background-color=#1e1e2e
      border-color=#89b4fa

      [urgency=critical]
      background-color=#b3261e
      text-color=#ffffff
      border-color=#f38ba8

      # Do-Not-Disturb mode (toggle with makoctl; see keybind below)
      [mode=do-not-disturb]
      invisible=1
    '';
  };
}
