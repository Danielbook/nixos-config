{...}: {
  # Manage kanshi services via Home-manager
  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";
    settings = [
      {
        profile.name = "home";
        profile.outputs = [
          {
            criteria = "Samsung Electric Company U28E850 HTPH300286";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Philips Consumer Electronics Company Philips 272C4 AU41322000654";
            status = "enable";
            position = "3840,0";
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
            criteria = "Samsung Electric Company U28E850 HTPK100298";
            status = "enable";
            position = "0,0";
          }
          {
            criteria = "Samsung Electric Company U28E850 HTPK100449";
            status = "enable";
            position = "3840,0";
          }
          {
            criteria = "eDP-1";
            status = "disable";
          }
        ];
      }
    ];
  };
}
