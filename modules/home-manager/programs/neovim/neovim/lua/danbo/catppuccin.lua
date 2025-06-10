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

