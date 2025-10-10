-- Indent-blankline configuration with smooth animations
local highlight = {
	"RainbowRed",
	"RainbowYellow",
	"RainbowBlue",
	"RainbowOrange",
	"RainbowGreen",
	"RainbowViolet",
	"RainbowCyan",
}

local hooks = require("ibl.hooks")
-- Create the highlight groups in the highlight setup hook
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
	vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
	vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
	vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
	vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
	vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
	vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

require("ibl").setup({
	-- Animated indent guides
	enabled = true,

	-- Debounce animation updates
	debounce = 100,

	-- Indent configuration
	indent = {
		char = "│",
		tab_char = "│",
		highlight = highlight,
		smart_indent_cap = true,
	},

	-- Whitespace configuration
	whitespace = {
		highlight = highlight,
		remove_blankline_trail = false,
	},

	-- Scope configuration for animated highlighting
	scope = {
		enabled = true,
		char = "│",
		highlight = highlight,
		priority = 500,
		include = {
			node_type = {
				["*"] = { "*" },
			},
		},
		exclude = {
			language = { "help" },
			node_type = {
				["*"] = {
					"source_file",
					"program",
				},
				python = {
					"module",
				},
			},
		},
	},

	-- Exclude certain filetypes
	exclude = {
		filetypes = {
			"help",
			"alpha",
			"dashboard",
			"neo-tree",
			"Trouble",
			"trouble",
			"lazy",
			"mason",
			"notify",
			"toggleterm",
			"lazyterm",
		},
		buftypes = {
			"terminal",
			"nofile",
			"quickfix",
			"prompt",
		},
	},
})

-- Setup scope highlighting with treesitter
hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
