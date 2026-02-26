{...}: {
  # Pro-audio low-latency tuning for USB audio interfaces
  # Provides ~5.3ms latency at 256 samples / 48kHz

  # PipeWire low-latency quantum settings
  services.pipewire.extraConfig.pipewire."10-low-latency" = {
    "context.properties" = {
      "default.clock.quantum" = 256;
      "default.clock.min-quantum" = 64;
      "default.clock.max-quantum" = 1024;
      "default.clock.rate" = 48000;
      "default.clock.allowed-rates" = [44100 48000 96000];
    };
  };

  # Matching low-latency pulse properties
  services.pipewire.extraConfig.pipewire-pulse."10-low-latency" = {
    "pulse.properties" = {
      "pulse.min.req" = "64/48000";
      "pulse.default.req" = "256/48000";
      "pulse.max.req" = "1024/48000";
      "pulse.min.quantum" = "64/48000";
    };
  };

  # PAM limits for the @audio group: real-time priority, unlimited memlock, nice
  security.pam.loginLimits = [
    {
      domain = "@audio";
      type = "-"; # Both soft and hard
      item = "memlock";
      value = "unlimited";
    }
    {
      domain = "@audio";
      type = "-";
      item = "rtprio";
      value = "99";
    }
    {
      domain = "@audio";
      type = "-";
      item = "nice";
      value = "-19";
    }
  ];
}
