{userConfig, ...}: {
  # Install git via home-manager module
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = userConfig.fullName;
        email = userConfig.email;
      };
      #signing = {
      #key = userConfig.gitKey;
      #    signByDefault = true;
      #};
      pull.rebase = "true";                    # Always rebase when pulling
      push.autoSetupRemote = "true";           # Auto-setup remote tracking for new branches
    };
  };

  # Configure delta (git diff pager)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      keep-plus-minus-markers = true;
      light = false;
      line-numbers = true;
      navigate = true;
      width = 280;
    };
  };

  # Enable catppuccin theming for git delta
  catppuccin.delta.enable = true;
}
