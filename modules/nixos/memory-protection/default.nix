{...}: {
  # Memory protection and monitoring configuration
  
  # Enable systemd-oomd for better OOM handling
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
  };

  # Configure systemd memory limits for user services
  systemd.user.extraConfig = ''
    DefaultMemoryMax=8G
    DefaultMemoryHigh=6G
  '';

  # Docker memory limits
  virtualisation.docker = {
    daemon.settings = {
      "default-ulimits" = {
        "memlock" = {
          "Hard" = 134217728;  # 128MB
          "Name" = "memlock";
          "Soft" = 134217728;
        };
      };
      "default-runtime" = "runc";
    };
  };

  # System-wide memory tuning
  boot.kernel.sysctl = {
    # Aggressive memory reclaim to prevent OOM
    "vm.swappiness" = 10;  # Prefer using RAM over swap when possible
    "vm.vfs_cache_pressure" = 150;  # Reclaim cache memory more aggressively
    "vm.dirty_ratio" = 5;  # Start writing dirty pages to disk earlier
    "vm.dirty_background_ratio" = 2;  # Background writeback at 2%
    
    # OOM killer tuning
    "vm.oom_kill_allocating_task" = 1;  # Kill the task that triggered OOM
    "vm.panic_on_oom" = 0;  # Don't panic on OOM, try to recover

    # Kernel hardening
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.yama.ptrace_scope" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
  };
}