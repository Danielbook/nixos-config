-- Treesitter highlight and indent are built into Neovim 0.11+
-- They are enabled automatically when parsers are available

-- Textobjects configuration
require("nvim-treesitter-textobjects").setup({
	select = {
		lookahead = true,
	},
	move = {
		set_jumps = true,
	},
})

local select = require("nvim-treesitter-textobjects.select")
local move = require("nvim-treesitter-textobjects.move")

-- Select keymaps
vim.keymap.set({ "x", "o" }, "af", function() select.select_textobject("@function.outer") end)
vim.keymap.set({ "x", "o" }, "if", function() select.select_textobject("@function.inner") end)
vim.keymap.set({ "x", "o" }, "ac", function() select.select_textobject("@class.outer") end)
vim.keymap.set({ "x", "o" }, "ic", function() select.select_textobject("@class.inner") end)
vim.keymap.set({ "x", "o" }, "aa", function() select.select_textobject("@parameter.outer") end)
vim.keymap.set({ "x", "o" }, "ia", function() select.select_textobject("@parameter.inner") end)

-- Move keymaps
vim.keymap.set({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer") end)
vim.keymap.set({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer") end)
vim.keymap.set({ "n", "x", "o" }, "]F", function() move.goto_next_end("@function.outer") end)
vim.keymap.set({ "n", "x", "o" }, "]C", function() move.goto_next_end("@class.outer") end)
vim.keymap.set({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer") end)
vim.keymap.set({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer") end)
vim.keymap.set({ "n", "x", "o" }, "[F", function() move.goto_previous_end("@function.outer") end)
vim.keymap.set({ "n", "x", "o" }, "[C", function() move.goto_previous_end("@class.outer") end)
