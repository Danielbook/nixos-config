{
  config,
  userConfig,
  ...
}: let
  bwSocket = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
in {
  # SSH configuration with Bitwarden SSH agent
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Use Bitwarden as SSH agent
    extraConfig = ''
      Host *
        IdentityAgent ${bwSocket}
    '';

    # Apply settings to all hosts
    settings."*" = {
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
    SSH_AUTH_SOCK = bwSocket;
  };
}
