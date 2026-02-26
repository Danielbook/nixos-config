{...}: {
  # Set TLP power profile
  services = {
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
        CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_SCALING_MIN_FREQ_ON_BAT = 400000;
        CPU_SCALING_MAX_FREQ_ON_BAT = 3000000;

        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        PLATFORM_PROFILE_ON_AC = "low-power";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        USB_EXCLUDE_BTUSB = 1;
        USB_AUTOSUSPEND = 1;
        USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = 1;
        
        # Exclude network devices and problematic USB devices from autosuspend
        # Network adapters and devices that fail resume with error -5
        # Also exclude USB hubs to prevent cascade failures
        USB_BLACKLIST = "0bda:8153 0bda:8152 0bda:8150 05e3:0610 05e3:0625 2109:2817 2109:0817 0409:005a";
        
        # Disable autosuspend for all USB hubs to prevent cascade failures
        USB_BLACKLIST_BTUSB = 1;
        USB_BLACKLIST_PHONE = 1;
        USB_BLACKLIST_PRINTER = 1;
        USB_BLACKLIST_WWAN = 1;
        
        # Blacklist network devices and NVIDIA GPU from runtime power management
        RUNTIME_PM_BLACKLIST = "0bda:8153 0bda:8152 0bda:8150 10de:*";

        AMDGPU_ABM_LEVEL_ON_AC = 0;
        AMDGPU_ABM_LEVEL_ON_BAT = 3;

        DISK_IOSCHED = ["none"];
        DISK_APM_LEVEL_ON_BAT = "1 1";

        SATA_LINKPWR_ON_BAT = "min_power";
        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "default"; # Conservative setting for NVIDIA compatibility

        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";

        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        SOUND_POWER_SAVE_ON_BAT = 1;
        SOUND_POWER_SAVE_CONTROLLER = "Y";

        # Battery charge thresholds for on-road usage
        START_CHARGE_THRESH_BAT0 = 85;
        STOP_CHARGE_THRESH_BAT0 = 90;
      };
    };

    power-profiles-daemon.enable = false;
  };

  # Disable fingerprint reader
  services.fprintd.enable = false;

  # Add udev rules to prevent USB hub and ethernet adapter suspension
  services.udev.extraRules = ''
    # Disable autosuspend for Realtek ethernet adapters
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8153", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8152", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8150", ATTR{power/autosuspend}="-1"
    
    # Disable autosuspend for USB hubs
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0610", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0625", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2109", ATTR{idProduct}=="2817", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2109", ATTR{idProduct}=="0817", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0409", ATTR{idProduct}=="005a", ATTR{power/autosuspend}="-1"

    # Disable autosuspend for USB audio class devices (audio interfaces)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="01", ATTR{power/autosuspend}="-1"
  '';
}
