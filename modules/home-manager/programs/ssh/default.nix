{userConfig, pkgs, ...}: {
  # SSH configuration with Bitwarden SSH agent
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Use Bitwarden as SSH agent
    extraConfig = ''
      Host *
        IdentityAgent ${
          if pkgs.stdenv.isDarwin
          then "/Users/${userConfig.name}/.bitwarden-ssh-agent.sock"
          else "/home/${userConfig.name}/.bitwarden-ssh-agent.sock"
        }
    '';

    # Apply settings to all hosts
    matchBlocks."*" = {
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
      compression = true;
      hashKnownHosts = true;
      userKnownHostsFile = "~/.ssh/known_hosts";
    };
  };

  # Disable other SSH agents to avoid conflicts
  services.ssh-agent.enable = false;
  
  # Set environment variables for Bitwarden SSH agent
  home.sessionVariables = {
    SSH_AUTH_SOCK = if pkgs.stdenv.isDarwin
      then "/Users/${userConfig.name}/.bitwarden-ssh-agent.sock"
      else "/home/${userConfig.name}/.bitwarden-ssh-agent.sock";
  };

  # Note: GNOME keyring has been removed from system configuration
  # No additional workarounds needed since keyring services are disabled
}