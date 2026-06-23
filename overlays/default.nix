_: {
  # Build lualine.nvim from source (work around nixpkgs hash mismatch bug)
  vim-plugins-from-source = final: prev: {
    vimPlugins = prev.vimPlugins // {
      lualine-nvim = final.vimUtils.buildVimPlugin {
        pname = "lualine.nvim";
        version = "2024-08-12";
        src = final.fetchFromGitHub {
          owner = "nvim-lualine";
          repo = "lualine.nvim";
          rev = "0a5a66803c7407767b799067986b4dc3036e1983";
          sha256 = "sha256-WcH2dWdRDgMkwBQhcgT+Z/ArMdm+VbRhmQftx4t2kNI=";
        };
      };
    };
  };
}
