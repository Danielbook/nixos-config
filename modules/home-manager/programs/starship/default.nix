{...}: {
  # Starship configuration
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # Format with better structure
      format = "$username$hostname$directory$git_branch$git_status$fill$cmd_duration$time$line_break$character";

      # Add newline between commands for better readability
      add_newline = true;

      # Username with icon
      username = {
        format = "[$user]($style) ";
        style_user = "bold lavender";
        show_always = false;
      };

      # Hostname with icon
      hostname = {
        format = "[@$hostname]($style) ";
        style = "bold lavender";
        ssh_only = true;
      };

      # Directory with beautiful formatting
      directory = {
        style = "bold lavender";
        format = "[$path]($style)[$read_only]($read_only_style) ";
        truncation_length = 3;
        truncate_to_repo = true;
        truncation_symbol = "…/";
        read_only = " 󰌾";
      };

      # Git branch with icon
      git_branch = {
        symbol = " ";
        style = "bold mauve";
        format = "[$symbol$branch(:$remote_branch)]($style) ";
      };

      # Enhanced git status with detailed info
      git_status = {
        style = "bold red";
        format = "([$all_status$ahead_behind]($style) )";
        conflicted = "🏳 ";
        ahead = "⇡\${count} ";
        behind = "⇣\${count} ";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
        up_to_date = "";
        untracked = "🤷 ";
        stashed = "📦 ";
        modified = "📝 ";
        staged = "[++$count](green) ";
        renamed = "👅 ";
        deleted = "🗑 ";
      };

      # Command duration
      cmd_duration = {
        min_time = 500;
        format = "[$duration]($style) ";
        style = "bold yellow";
      };

      # Time display
      time = {
        disabled = false;
        format = "[$time]($style) ";
        style = "bold blue";
        time_format = "%T";
      };

      # Battery indicator
      battery = {
        full_symbol = "🔋 ";
        charging_symbol = "⚡ ";
        discharging_symbol = "💀 ";
        display = [
          {
            threshold = 10;
            style = "bold red";
          }
          {
            threshold = 30;
            style = "bold yellow";
          }
        ];
      };

      # Fill to separate left and right
      fill = {
        symbol = " ";
      };

      # Enhanced character prompt with more symbols
      character = {
        success_symbol = "[❯](bold purple)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold green)";
      };

      # Language modules with nerd font icons
      aws = {
        disabled = true;
      };

      nix_shell = {
        symbol = " ";
        format = "[$symbol$state( \\($name\\))]($style) ";
        style = "bold blue";
      };

      docker_context = {
        symbol = " ";
        format = "[$symbol$context]($style) ";
      };

      golang = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      helm = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      gradle = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      java = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      kotlin = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      lua = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      nodejs = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      package = {
        symbol = "󰏗 ";
        format = "[$symbol$version]($style) ";
      };

      php = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      python = {
        symbol = " ";
        format = "[(\${symbol}\${pyenv_prefix}(\${version} )(\\($virtualenv\\) ))]($style)";
      };

      rust = {
        symbol = " ";
        format = "[$symbol($version )]($style)";
      };

      terraform = {
        symbol = "󱁢 ";
        format = "[$symbol$workspace]($style) ";
      };

      # Kubernetes context display
      kubernetes = {
        disabled = false;
        style = "bold pink";
        symbol = "󱃾 ";
        format = "[$symbol$context( \\($namespace\\))]($style)";
      };

      # Right side format
      right_format = "$kubernetes";
    };
  };

  # Enable catppuccin theming for starship.
  catppuccin.starship.enable = true;
}
