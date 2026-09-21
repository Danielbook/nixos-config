_: {
  # Zoxide - a smarter cd command
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;

    # Add helpful options
    options = [
      "--cmd cd" # Replace cd command with zoxide
    ];
  };

  # Keep network mounts out of the db: `zoxide query -l` stats every entry, so
  # one dir on an unreachable NFS automount stalls sesh/fzf for seconds.
  # ($HOME is zoxide's default exclude, kept.)
  home.sessionVariables._ZO_EXCLUDE_DIRS = "$HOME:$HOME/mnt/**:/mnt/**";
}
