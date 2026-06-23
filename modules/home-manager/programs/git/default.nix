{
  userConfig,
  pkgs,
  ...
}:
{
  # Install git via home-manager module
  programs.git = {
    enable = true;
    lfs.enable = true;
    includes = [
      {
        condition = "hasconfig:remote.*.url:git@gitlab.*/**";
        contents.user.signingKey = "~/.ssh/id_rsa";
      }
      {
        condition = "gitdir:~/Documents/repositories/personal/";
        contents.user = {
          name = "Daniel Böök";
          email = "daniel@bookorjeman.se";
        };
      }
      {
        condition = "gitdir:~/Documents/repositories/work/";
        contents.user = {
          name = "Daniel Böök";
          email = "daniel.book@configura.com";
        };
      }
    ];
    settings = {
      user = {
        name = userConfig.fullName;
        inherit (userConfig) email;
      };
      gpg.format = "ssh";
      signing = {
        key = "~/.ssh/id_ed25519";
        signByDefault = true;
      };
      pull.rebase = "true"; # Always rebase when pulling
      push.autoSetupRemote = "true"; # Auto-setup remote tracking for new branches
      # Push/pull GitHub over SSH (Bitwarden SSH agent) even when the remote is
      # an HTTPS URL — avoids the interactive "Username for https://github.com" prompt.
      url."git@github.com:".insteadOf = "https://github.com/";
      credential."https://git.configura.com".helper = [
        ""
        "${pkgs.glab}/bin/glab auth git-credential"
      ];
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
