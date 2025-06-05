return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      ensure_installed = {
        "vimdoc", "javascript", "typescript", "lua",
        "go", "jsdoc", "bash", "go"
      },

      -- Automatically install missing parsers when entering buffer
      -- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
      auto_install = true,

      indent = { enable = true },
      highlight = { enable = true },
    })
  end
}
