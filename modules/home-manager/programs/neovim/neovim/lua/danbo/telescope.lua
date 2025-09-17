local telescope = require("telescope")

telescope.setup({
	extensions = {
		fzf = {},
		["ui-select"] = require("telescope.themes").get_dropdown({}),
	},
})

-- Load telescope extensions
telescope.load_extension("fzf")
telescope.load_extension("ui-select")
