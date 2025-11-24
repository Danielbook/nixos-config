-- precognition.nvim - Show available motion hints
-- Displays virtual text showing what motions are available from cursor position

require("precognition").setup({
	-- Start disabled by default (use <leader>pt to toggle on)
	startVisible = false,

	-- Show hints in buffer types
	showBlankVirtLine = true,

	-- Highlight group for hints
	highlightColor = { link = "Comment" },

	-- Show these motion hints
	hints = {
		-- Horizontal motions
		["^"] = { text = "^", prio = 10 },
		["$"] = { text = "$", prio = 10 },
		["w"] = { text = "w", prio = 10 },
		["b"] = { text = "b", prio = 10 },
		["e"] = { text = "e", prio = 10 },

		-- Vertical motions (gutter signs)
		["0"] = { text = "0", prio = 1 },
		["{"] = { text = "{", prio = 1 },
		["}"] = { text = "}", prio = 1 },
	},

	-- Gutter signs for vertical navigation hints
	gutterHints = {
		["G"] = { text = "G", prio = 10 },
		["gg"] = { text = "gg", prio = 10 },
		["{"] = { text = "{", prio = 9 },
		["}"] = { text = "}", prio = 9 },
	},

	-- Disabled filetypes
	disabled_fts = {
		"NvimTree",
		"neo-tree",
		"TelescopePrompt",
		"alpha",
		"lazy",
		"mason",
	},
})
