local telescope = require("telescope")

telescope.setup({
	extensions = {
		fzf = {},
		["ui-select"] = require("telescope.themes").get_dropdown({}),
	},
})
