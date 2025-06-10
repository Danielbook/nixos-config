require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"lua",
		"vimdoc",
		"go",
		"bash",
		"html",
		"javascript",
		"typescript",
		"jsdoc",
	},
	auto_install = false, -- 🚫 disables automatic writing
	highlight = { enable = true },
	indent = { enable = true },
})
