-- hardtime.nvim - Break bad habits and learn better Vim motions
-- Blocks repeated inefficient keys and suggests better alternatives

require("hardtime").setup({
	-- Maximum number of repetitions allowed within the time window
	max_count = 3,

	-- Time window in milliseconds
	max_time = 1000,

	-- Disable arrow keys entirely (force hjkl then better motions)
	disable_mouse = false,

	-- Hint messages when you use inefficient motions
	hint = true,

	-- Notification settings
	notification = true,
	allow_different_key = true,

	-- Keys to restrict (blocks spamming these)
	restricted_keys = {
		["h"] = { "n", "x" },
		["j"] = { "n", "x" },
		["k"] = { "n", "x" },
		["l"] = { "n", "x" },
		["-"] = { "n", "x" },
		["+"] = { "n", "x" },
		["gj"] = { "n", "x" },
		["gk"] = { "n", "x" },
		["<CR>"] = { "n", "x" },
		["<C-M>"] = { "n", "x" },
		["<C-N>"] = { "n", "x" },
		["<C-P>"] = { "n", "x" },
	},

	-- Disabled filetypes (where hardtime won't run)
	disabled_filetypes = {
		"qf",
		"netrw",
		"NvimTree",
		"neo-tree",
		"lazy",
		"mason",
		"oil",
		"TelescopePrompt",
	},

	-- Custom hint messages for better learning
	hints = {
		["k%^"] = {
			message = function()
				return "Use - instead of k^" .. " [hardtime]"
			end,
			length = 2,
		},
		["d%$"] = {
			message = function()
				return "Use D instead of d$" .. " [hardtime]"
			end,
			length = 2,
		},
	},
})

-- Keybindings for hardtime commands
vim.keymap.set("n", "<leader>ht", "<cmd>Hardtime toggle<CR>", { desc = "Toggle Hardtime" })
vim.keymap.set("n", "<leader>hr", "<cmd>Hardtime report<CR>", { desc = "Hardtime Report" })
