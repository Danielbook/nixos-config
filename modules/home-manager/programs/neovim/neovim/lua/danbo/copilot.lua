require("copilot").setup({
	suggestion = {
		enabled = false, -- Disable inline suggestions (we'll use cmp instead)
	},
	panel = {
		enabled = false, -- Disable the panel (we'll use cmp instead)
	},
	filetypes = {
		yaml = true,
		markdown = true,
		help = false,
		gitcommit = true,
		gitrebase = false,
		["."] = false,
	},
})

require("copilot_cmp").setup()
