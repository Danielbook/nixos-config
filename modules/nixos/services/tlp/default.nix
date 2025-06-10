{...}: {
  # Set TLP power profile
  services = {
    tlp = {
      enable = true;
      settings = {
        # Selects the CPU scaling governor for automatic frequency scaling.
        # For Intel Core i 2nd gen. (“Sandy Bridge”) or newer Intel CPUs. Supported governors are:
        #  powersave – recommended (kernel default)
        #  performance
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";

        # Set Intel CPU energy/performance policy HWP.EPP. Possible values are
        #  performance
        #  balance_performance
        #  default
        #  balance_power
        #  power
        # for tlp-stat Version 1.3 and higher 'tlp-stat -p'
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

        # Disable CPU “turbo boost” (Intel) or “turbo core” (AMD) feature (0 = disable / 1 = allow).
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        INTEL_GPU_MIN_FREQ_ON_AC = 500;

        PLATFORM_PROFILE_ON_AC = "low-power";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        USB_EXCLUDE_BTUSB = 1;

        DISK_IOSCHED = ["none"];

        # Battery charge thresholds for on-road usage
        START_CHARGE_THRESH_BAT0 = 85;
        STOP_CHARGE_THRESH_BAT0 = 90;

        # Set the “Advanced Power Management Level”. Possible values range between 1 and 255.
        #  1 – max power saving / minimum performance – Important: this setting may lead to increased disk drive wear and tear because of excessive read-write head unloading (recognizable from the clicking noises)
        #  128 – compromise between power saving and wear (TLP standard setting on battery)
        #  192 – prevents excessive head unloading of some HDDs
        #  254 – minimum power saving / max performance (TLP standard setting on AC)
        #  255 – disable APM (not supported by some disk models)
        #  keep – special value to skip this setting for the particular disk (synonym: _)
        DISK_APM_LEVEL_ON_AC = "254 254";
        DISK_APM_LEVEL_ON_BAT = "128 128";
      };
    };
    power-profiles-daemon = {
      enable = false;
    };
  };

  # Disable fingerprint reader
  services.fprintd.enable = false;
}
