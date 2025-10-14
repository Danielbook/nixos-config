local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

-- Neovim ASCII art header
dashboard.section.header.val = {
	[[                                                                       ]],
	[[                                                                       ]],
	[[                                                                       ]],
	[[                                                                       ]],
	[[                                                                     ]],
	[[       ████ ██████           █████      ██                     ]],
	[[      ███████████             █████                             ]],
	[[      █████████ ███████████████████ ███   ███████████   ]],
	[[     █████████  ███    █████████████ █████ ██████████████   ]],
	[[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
	[[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
	[[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
	[[                                                                       ]],
	[[                                                                       ]],
	[[                                                                       ]],
}

dashboard.section.header.opts.hl = "AlphaHeader"

-- Buttons with your actual keybindings
dashboard.section.buttons.val = {
	dashboard.button("SPC f f", "󰈞  Find Files", ":Telescope find_files<CR>"),
	dashboard.button("SPC s g", "󰱼  Live Grep", ":Telescope live_grep<CR>"),
	dashboard.button("C-n", "󰙅  File Explorer", ":Neotree filesystem reveal left<CR>"),
	dashboard.button("SPC g s", "󰊢  Git Status", ":Git<CR>"),
	dashboard.button("SPC u", "󰣜  Undo Tree", ":UndotreeToggle<CR>"),
	dashboard.button("SPC q", "󰈆  Quit", ":qa<CR>"),
}

-- Footer with current date
local function get_footer()
	return os.date("%A, %B %d, %Y")
end

dashboard.section.footer.val = {
	get_footer(),
}
dashboard.section.footer.opts.hl = "AlphaFooter"

-- Layout with proper padding for centering
dashboard.config.layout = {
	{ type = "padding", val = 2 },
	dashboard.section.header,
	{ type = "padding", val = 2 },
	dashboard.section.buttons,
	{ type = "padding", val = 1 },
	dashboard.section.footer,
}

alpha.setup(dashboard.config)
vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
