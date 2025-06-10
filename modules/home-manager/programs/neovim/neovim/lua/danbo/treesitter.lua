local treesitter = require("nvim-treesitter.configs")

tresitter.setup({
  ensure_installed = {
    "vimdoc", "javascript", "typescript", "lua",
    "go", "jsdoc", "bash"
  },
  auto_install = false, -- Set false since you’re not using the CLI dynamically
  highlight = { enable = true },
  indent = { enable = true },
})

