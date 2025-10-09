{...}: {
  # Zoxide - a smarter cd command
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    
    # Add helpful options
    options = [
      "--cmd cd"  # Replace cd command with zoxide
    ];
  };
}