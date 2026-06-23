{ userConfig, ... }:
{
  # USB Serial device configuration for ESP32, Arduino, and other development boards
  # Supports common USB-to-serial chips: CH340, CP210x, FTDI, PL2303

  # Add user to dialout group for serial port access
  users.users.${userConfig.name}.extraGroups = [
    "dialout"
    "uucp"
  ];

  # udev rules for USB serial devices
  services.udev.extraRules = ''
    # CH340/CH341 USB to serial adapter (common in ESP32, Arduino clones)
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="7523", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0660", GROUP="dialout"

    # CH340 variant
    SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="5523", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="5523", MODE="0660", GROUP="dialout"

    # Silicon Labs CP210x USB to UART Bridge (common in ESP32 dev boards)
    SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0660", GROUP="dialout"

    # FTDI USB to serial adapter (FT232, FT2232, etc.)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6001", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0660", GROUP="dialout"

    # Prolific PL2303 USB to serial adapter
    SUBSYSTEM=="usb", ATTR{idVendor}=="067b", ATTR{idProduct}=="2303", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", MODE="0660", GROUP="dialout"

    # Prevent USB serial devices from being auto-suspended (can cause connection issues)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{power/autosuspend}="-1"
  '';

  # Ensure CH340/CH341 kernel module is loaded
  boot.kernelModules = [ "ch341" ];
}
