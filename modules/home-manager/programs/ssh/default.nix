{userConfig, ...}: {
  # SSH configuration with Bitwarden SSH agent
  programs.ssh = {
    enable = true;
    
    # Use Bitwarden as SSH agent
    extraConfig = ''
      Host *
        IdentityAgent /home/${userConfig.name}/.bitwarden-ssh-agent.sock
    '';
    
    # Common SSH settings
    serverAliveInterval = 60;
    serverAliveCountMax = 3;
    compression = true;
    
    # Security settings
    hashKnownHosts = true;
    userKnownHostsFile = "~/.ssh/known_hosts";
  };

  # Disable other SSH agents to avoid conflicts
  services.ssh-agent.enable = false;
  
  # Set environment variables for Bitwarden SSH agent
  home.sessionVariables = {
    SSH_AUTH_SOCK = "/home/${userConfig.name}/.bitwarden-ssh-agent.sock";
  };

  # Note: GNOME keyring has been removed from system configuration
  # No additional workarounds needed since keyring services are disabled
}