return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000, -- Load before other UI plugins
  config = function()
    require("catppuccin").setup({
      transparent_background = true, -- Enable transparency
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        treesitter = true,
      },
    })
    vim.cmd.colorscheme "catppuccin"
  end
}

