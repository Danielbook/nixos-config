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
        alpha-nvim
        catppuccin-nvim
        cmp-nvim-lsp
        cmp_luasnip
        friendly-snippets
        lualine-nvim
        luasnip
        neo-tree-nvim
        none-ls-nvim
        nui-nvim
        nvim-cmp
        nvim-lspconfig
        nvim-treesitter-with-plugins
        nvim-web-devicons
        peek-nvim
        plenary-nvim
        telescope-fzf-native-nvim
        telescope-nvim
        telescope-ui-select-nvim
        undotree
      ];

    extraPackages = with pkgs; [
      alejandra
      gopls
      isort
      lua-language-server
      markdownlint-cli
      nil
      nixd
      nodePackages.bash-language-server
      nodePackages.prettier
      nodePackages.typescript-language-server
      shellcheck
      shfmt
      stylua
      tailwindcss-language-server
      terraform-ls
      vscode-langservers-extracted
      yaml-language-server
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
