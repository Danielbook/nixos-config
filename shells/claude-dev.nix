{pkgs}: {
  devShells.claude-dev = pkgs.mkShell {
    buildInputs = with pkgs; [
      nodejs_22
      npm
    ];

    shellHook = ''
      # Create a local npm prefix
      export NPM_CONFIG_PREFIX="$PWD/.npm-local"
      export PATH="$PWD/.npm-local/bin:$PATH"

      # Install Claude Code locally if not present
      if [ ! -f ".npm-local/bin/claude-code" ]; then
        echo "Installing Claude Code in development shell..."
        npm install -g @anthropic-ai/claude-code
      fi
    '';
  };
}
