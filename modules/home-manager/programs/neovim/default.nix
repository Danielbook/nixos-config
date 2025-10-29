{
  pkgs,
  lib,
  ...
}: let
  fromGitHub = {
    repo,
    ref ? null,
    rev ? null,
  }: let
    gitArgs = lib.filterAttrs (name: value: value != null) {
      url = "https://github.com/${repo}.git";
      inherit ref;
      inherit rev;
    };
    src = builtins.fetchGit gitArgs;
  in
    pkgs.vimUtils.buildVimPlugin {
      inherit src;
      pname = "${lib.strings.sanitizeDerivationName repo}";
      version =
        if rev != null
        then rev
        else ref;
    };
in {
  # Neovim text editor configuration
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    defaultEditor = true;
    withNodeJs = true;
    viAlias = true;
    vimAlias = true;

    # Use the Nix package search engine to find
    # even more plugins : https://search.nixos.org/packages
    plugins = let
      nvim-treesitter-with-plugins = pkgs.vimPlugins.nvim-treesitter.withPlugins (treesitter-plugins:
        with treesitter-plugins; [
          bash
          go
          javascript
          jsdoc
          lua
          nix
          typescript
        ]);
    in
      with pkgs.vimPlugins; [
        alpha-nvim                        # Startup screen with custom dashboard
        catppuccin-nvim                   # Catppuccin colorscheme
        cmp-nvim-lsp                      # LSP completion source for nvim-cmp
        cmp-path                          # Path completion source for nvim-cmp
        cmp-buffer                        # Buffer completion source for nvim-cmp
        cmp_luasnip                       # LuaSnip completion source for nvim-cmp
        copilot-lua                       # GitHub Copilot integration
        copilot-cmp                       # Copilot integration with nvim-cmp
        CopilotChat-nvim                  # Copilot chat for conversations with AI
        friendly-snippets                 # Collection of useful snippets
        gitsigns-nvim                     # Git signs in the gutter
        lualine-nvim                      # Fast and customizable statusline
        luasnip                           # Snippet engine for Neovim
        neo-tree-nvim                     # File explorer tree
        none-ls-nvim                      # Null-ls alternative for formatters/linters
        nui-nvim                          # UI component library
        nvim-cmp                          # Completion engine
        nvim-lspconfig                    # LSP configuration helper
        nvim-treesitter-with-plugins      # Syntax highlighting and parsing
        nvim-treesitter-textobjects       # Textobjects for treesitter (af, if, etc.)
        nvim-ts-autotag                   # Auto close/rename HTML tags
        nvim-web-devicons                 # File type icons
        peek-nvim                         # Markdown preview
        plenary-nvim                      # Lua utility library
        telescope-fzf-native-nvim         # FZF integration for Telescope
        telescope-nvim                    # Fuzzy finder
        telescope-ui-select-nvim          # Use Telescope for vim.ui.select
        undotree                          # Undo history visualizer
        vim-fugitive                      # Git integration
        vim-be-good                       # Vim practice game
        which-key-nvim                    # Show available keybindings

        # Animation plugins for smooth UI experience
        mini-nvim                         # Collection of small plugins including animate
        noice-nvim                        # Better UI for messages, cmdline and popupmenu
        nvim-notify                       # Beautiful notification system
        indent-blankline-nvim             # Indent guides with animations

        # Navigation learning plugins
        hardtime-nvim                     # Break bad habits, suggest better motions
        precognition-nvim                 # Show available motion hints
      ];

    extraPackages = with pkgs; [
      alejandra                         # Nix code formatter
      gopls                             # Go language server
      isort                             # Python import sorter
      lua-language-server               # Lua language server
      markdownlint-cli                  # Markdown linter
      nil                               # Nix language server
      nixd                              # Alternative Nix language server
      nodePackages.bash-language-server # Bash language server
      nodePackages.prettier            # Code formatter for web languages
      shellcheck                        # Shell script static analysis
      shfmt                             # Shell script formatter
      stylua                            # Lua code formatter
      tailwindcss-language-server       # Tailwind CSS language server
      terraform-ls                      # Terraform language server
      vscode-langservers-extracted      # HTML/CSS/JSON language servers
      vtsls                             # TypeScript/JavaScript LSP with enhanced CodeLens
      yaml-language-server              # YAML language server
    ];
  };

  # source lua config from this repo
  xdg.configFile = {
    "nvim" = {
      source = ./neovim;
      recursive = true;
    };
  };
}
