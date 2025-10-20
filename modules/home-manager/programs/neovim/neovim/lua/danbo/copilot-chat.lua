require("CopilotChat").setup({
	debug = false,
	window = {
		layout = "float",
		width = 0.8,
		height = 0.8,
		border = "rounded",
	},
	mappings = {
		complete = {
			detail = "Use @<Tab> or /<Tab> for options.",
			insert = "<Tab>",
		},
		close = {
			normal = "q",
			insert = "<C-c>",
		},
		reset = {
			normal = "<C-r>",
			insert = "<C-r>",
		},
		submit_prompt = {
			normal = "<CR>",
			insert = "<C-s>",
		},
	},
})
