-- Mini.animate configuration for smooth animations
local animate = require("mini.animate")

animate.setup({
	-- Cursor path animation
	cursor = {
		enable = true,
		timing = animate.gen_timing.linear({ duration = 200, unit = "total" }),
		path = animate.gen_path.line({
			predicate = function()
				return true
			end,
		}),
	},

	-- Scroll animation (disabled: conflicts with holding C-d/C-u for rapid scrolling)
	scroll = {
		enable = false,
	},

	-- Window resize animation
	resize = {
		enable = true,
		timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
		subresize = animate.gen_subresize.equal({
			predicate = function()
				return true
			end,
		}),
	},

	-- Window open/close animation
	open = {
		enable = true,
		timing = animate.gen_timing.exponential({ duration = 100, unit = "total" }),
		winconfig = animate.gen_winconfig.wipe({ direction = "from_edge" }),
		winblend = animate.gen_winblend.linear({ from = 80, to = 0 }),
	},

	close = {
		enable = true,
		timing = animate.gen_timing.exponential({ duration = 100, unit = "total" }),
		winconfig = animate.gen_winconfig.wipe({ direction = "to_edge" }),
		winblend = animate.gen_winblend.linear({ from = 0, to = 80 }),
	},
})
