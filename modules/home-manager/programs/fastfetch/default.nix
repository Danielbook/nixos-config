_: {
  # Install and configure fastfetch via home-manager module
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        type = "auto";
        padding = {
          right = 1;
        };
      };
      display = {
        separator = "->   ";
      };
      modules = [
        {
          type = "title";
          format = "{#33}{1}{#39}@{#36}{2}{#0}";
        }
        "break"
        {
          key = " {#36} OS{#0}";
          type = "os";
        }
        {
          key = " {#36}󰌢 Host{#0}";
          type = "host";
        }
        {
          key = " {#36} Kernel{#0}";
          type = "kernel";
        }
        {
          key = " {#36}󰏖 Packages{#0}";
          type = "packages";
        }
        {
          key = " {#36}󰅐 Uptime{#0}";
          type = "uptime";
        }
        {
          key = " {#36}󰍹 Display{#0}";
          type = "display";
          compactType = "original-with-refresh-rate";
        }
        {
          key = " {#36} WM{#0}";
          type = "wm";
        }
        {
          key = " {#36} Shell{#0}";
          type = "shell";
        }
        {
          key = " {#36} Terminal{#0}";
          type = "terminal";
        }
        "break"
        {
          key = " {#36}󰻠 CPU{#0}";
          type = "cpu";
        }
        {
          key = " {#36}󰍛 GPU{#0}";
          type = "gpu";
        }
        {
          key = " {#36}󰑭 Memory{#0}";
          type = "memory";
        }
        "break"
        {
          key = " {#36}󰩟 Local IP{#0}";
          type = "localip";
        }
        "break"
        {
          type = "colors";
        }
      ];
    };
  };
}
