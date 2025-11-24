{...}: {
  # Manage kanshi services via Home-manager
  # Disabled in favor of native Hyprland monitor configuration
  services.kanshi = {
    enable = false;
    systemdTarget = "graphical-session.target";
    settings = [
      {
        profile.name = "home";
        profile.outputs = [
          {
            criteria = "Philips Consumer Electronics Company 34M2C6500 AU42507000018";
            status = "enable";
            position = "0,0";
            scale = 1.0;
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      }
      {
        profile.name = "undocked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }
        ];
      }
      {
        profile.name = "work";
        profile.outputs = [
          {
            criteria = "Samsung Electric Company U28E850 HTPK100449";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      }
      {
        profile.name = "benq";
        profile.outputs = [
          {
            criteria = "BNQ BenQ LCD C1H04453SL0";
            status = "enable";
            position = "0,0";
            mode = "3840x2160@60.00";
            scale = 1.0;
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      }
      {
        profile.name = "mirror";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Philips Consumer Electronics Company 34M2C6500 AU42507000018";
            status = "enable";
            position = "0,0";
          }
        ];
      }
    ];
  };
}
