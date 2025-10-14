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

-- MRU (Most Recently Used files)
local function get_mru()
	local mru_list = {}
	local oldfiles = vim.v.oldfiles
	local cwd = vim.fn.getcwd()
	local max_shown = 5
	local count = 0

	-- Helper to shorten paths
	local function shorten_path(path)
		local max_len = 50
		if #path <= max_len then
			return path
		end
		-- Truncate from middle
		local start_len = 20
		local end_len = 27
		return path:sub(1, start_len) .. "..." .. path:sub(-end_len)
	end

	-- Add header
	table.insert(mru_list, { type = "text", val = "Recent Files", opts = { hl = "SpecialComment", position = "center" } })
	table.insert(mru_list, { type = "padding", val = 1 })

	for _, file in ipairs(oldfiles) do
		-- Only show files from current directory and that exist
		if file:sub(1, #cwd) == cwd and vim.fn.filereadable(file) == 1 then
			local short_path = vim.fn.fnamemodify(file, ":~:.")
			local display_path = shorten_path(short_path)
			count = count + 1
			table.insert(
				mru_list,
				dashboard.button(tostring(count), "  " .. display_path, ":e " .. file .. "<CR>")
			)
			if count >= max_shown then
				break
			end
		end
	end

	return mru_list
end

dashboard.section.mru = {
	type = "group",
	val = get_mru,
}

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
	{ type = "padding", val = 2 },
	dashboard.section.mru,
	{ type = "padding", val = 1 },
	dashboard.section.footer,
}

alpha.setup(dashboard.config)
vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
