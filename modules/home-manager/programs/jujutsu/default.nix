{userConfig, ...}: {
  # Install jujutsu via home-manager module
  programs.jujutsu = {
    enable = true;
    
    settings = {
      # JSON Schema for validation and IDE support
      "$schema" = "https://jj-vcs.github.io/jj/latest/config-schema.json";
      
      # User configuration
      user = {
        name = userConfig.fullName;
        email = userConfig.email;
      };
      
      # UI and display settings
      ui = {
        # Default command when running jj with no args
        default-command = "log";
        
        # Use delta for diffs (consistent with git config)
        diff-formatter = "delta";
        pager = "delta";
        
        # Graph styling for better visualization
        graph.style = "square";
        
        # Editor configuration
        editor = "nvim";
        
        # Enable synthetic elided nodes for cleaner logs
        log-synthetic-elided-nodes = true;
        
        # Color and display preferences
        color = "always";
        
        # Enable sign-off trailers in commits
        should-sign-off = true;
      };
      
      # Git integration settings
      git = {
        # Don't automatically create local bookmarks for remote branches
        auto-local-bookmark = false;
        
        # Prefix for push bookmarks to organize remote branches
        push-bookmark-prefix = "push-";
        
        # Prevent accidentally pushing work-in-progress commits
        private-commits = "description(glob:'wip:*') | description(glob:'draft:*') | description(glob:'tmp:*')";
        
        # Write change-id headers for better tracking
        write-change-id-header = true;
        
        # Push to git remotes by default
        # Note: push-bookmark-prefix is deprecated, using templates instead
      };
      
      # Snapshot settings for working copy management
      snapshot = {
        auto-update-stale = true;
      };
      
      # Revset aliases for common workflow patterns
      revset-aliases = {
        # Your commits only
        "mine" = "author(exact:\"${userConfig.email}\")";
        
        # Main/master branch (handles both naming conventions)
        "trunk" = "main@origin | master@origin | main | master";
        
        # Current working stack
        "stack" = "ancestors(@) ~ trunk()";
        
        # Active development area
        "work" = "stack | @";
        
        # Upstream changes not yet in trunk
        "upstream" = "remote_bookmarks()..trunk()";
        
        # Local commits not yet pushed
        "local" = "mine() ~ ancestors(remote_bookmarks())";
        
        # Commits in current branch/stack
        "current-branch" = "ancestors(@) ~ ancestors(trunk())";
        
        # Recently modified commits (last 7 days)
        "recent" = "committer_date(after:'1 week ago')";
        
        # Bookmarked commits
        "bookmarked" = "bookmarks()";
      };
      
      # Custom revsets for log and operations
      revsets = {
        # Smart log showing relevant commits
        log = "@ | stack | trunk() | recent & mine()";
        
        # Prioritize trunk and merges in graph display
        log-graph-prioritize = "trunk() | merges()";
      };
      
      # Template aliases for better formatting
      template-aliases = {
        # Short change ID formatting
        "format_short_change_id(id)" = "id.shortest(4)";
        
        # Relative timestamp formatting
        "format_timestamp(timestamp)" = "timestamp.ago()";
        
        # Author formatting with email
        "format_author(commit)" = "commit.author().name() + ' <' + commit.author().email() + '>'";
        
        # Compact commit summary
        "format_summary(commit)" = "commit.description().first_line()";
      };
      
      # Templates for modern configuration
      templates = {
        git_push_bookmark = "\"push-\" ++ change_id.short()";
      };
      
      # Merge tools configuration
      merge-tools = {
        delta = {
          program = "delta";
          diff-args = ["--color=always" "$left" "$right"];
        };
      };
      
      # Signing configuration (commented out, enable if you have GPG setup)
      # signing = {
      #   sign-all = true;
      #   backend = "gpg";
      #   key = userConfig.email;  # or specific key ID
      # };
      
      # Aliases for common operations
      aliases = {
        # Short log with limited entries
        "l" = ["log" "-n" "10"];
        "ll" = ["log" "-n" "20"];
        
        # Status shortcuts
        "s" = ["status"];
        "st" = ["status"];
        
        # Diff shortcuts
        "d" = ["diff"];
        "ds" = ["diff" "--stat"];
        "dc" = ["diff" "--color-words"];
        
        # Branch operations
        "co" = ["checkout"];
        "br" = ["bookmark"];
        
        # Squash and edit shortcuts
        "sq" = ["squash"];
        "amend" = ["squash" "--into" "@-"];
        
        # Rebase operations
        "rb" = ["rebase"];
        
        # Push operations with safety
        "push" = ["git" "push"];
        "force-push" = ["git" "push" "--force-with-lease"];
        
        # Quick commit operations
        "uncommit" = ["edit" "@-"];
        
        # Working copy operations
        "abandon-all" = ["abandon" "all()"];
        "restore-all" = ["restore"];
      };
      
      # Color customization for better visibility
      colors = {
        # Change ID colors
        "change_id" = "bright blue";
        "commit_id" = "blue";
        
        # Status colors
        "working_copy" = "bright green";
        "current_operation" = "bright yellow";
        
        # Diff colors (if not using delta)
        "diff.header" = "bright white";
        "diff.file_header" = { fg = "bright white"; bold = true; };
        "diff.hunk_header" = "cyan";
        "diff.added" = "bright green";
        "diff.removed" = "bright red";
        "diff.modified" = "bright cyan";
        
        # Graph colors
        "node" = "bright blue";
        "node.immutable" = "bright cyan";
        "node.conflict" = "bright red";
      };
    };
  };
}