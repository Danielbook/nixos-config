local wk = require("which-key")

wk.setup({
	preset = "modern",
	delay = 300,
	triggers = {
		{ "<leader>", mode = { "n", "v" } },
		{ "<localleader>", mode = { "n", "v" } },
	},
	plugins = {
		marks = true,
		registers = true,
		spelling = {
			enabled = true,
			suggestions = 20,
		},
		presets = {
			operators = true,
			motions = true,
			text_objects = true,
			windows = true,
			nav = true,
			z = true,
			g = true,
		},
	},
	win = {
		border = "rounded",
		padding = { 2, 2, 2, 2 },
	},
	layout = {
		height = { min = 4, max = 25 },
		width = { min = 20, max = 50 },
		spacing = 3,
		align = "left",
	},
	show_help = true,
	show_keys = true,
	disable = {
		buftypes = {},
		filetypes = { "TelescopePrompt" },
	},
})

-- Register all keymaps with descriptions
wk.add({
	-- ═══════════════════════════════════════════════════════════════════════════════
	-- LEADER KEY GROUPS
	-- ═══════════════════════════════════════════════════════════════════════════════

	-- Format operations
	{ "<leader>f", group = "󰉼 Format" },

	-- Search/Grep operations
	{ "<leader>s", group = " Search" },
	{ "<leader>sf", desc = "Search Files" },
	{ "<leader>sb", desc = "Search Buffers" },
	{ "<leader>sw", desc = "Search Word under cursor" },
	{ "<leader>sW", desc = "Search WORD under cursor" },
	{ "<leader>sg", desc = "Live Grep" },
	{ "<leader>sh", desc = "Search Help" },

	-- Git operations (Fugitive)
	{ "<leader>g", group = "󰊢 Git" },
	{ "<leader>gs", desc = "Git Status" },
	{ "<leader>gc", desc = "Git Commit" },
	{ "<leader>gp", desc = "Git Push" },
	{ "<leader>gP", desc = "Git Pull" },
	{ "<leader>gb", desc = "Git Blame" },
	{ "<leader>gd", desc = "Git Diff" },
	{ "<leader>gl", desc = "Git Log" },
	{ "<leader>gL", desc = "Git Log (current file)" },
	{ "<leader>gr", desc = "Git Read (checkout file)" },
	{ "<leader>gw", desc = "Git Write (stage file)" },

	-- Git Hunks (GitSigns)
	{ "<leader>h", group = "󰊢 Git Hunks" },
	{ "<leader>hs", desc = "Stage Hunk", mode = { "n", "v" } },
	{ "<leader>hr", desc = "Reset Hunk", mode = { "n", "v" } },
	{ "<leader>hS", desc = "Stage Buffer" },
	{ "<leader>hu", desc = "Undo Stage Hunk" },
	{ "<leader>hR", desc = "Reset Buffer" },
	{ "<leader>hp", desc = "Preview Hunk" },
	{ "<leader>hb", desc = "Blame Line (full)" },
	{ "<leader>hd", desc = "Diff This" },
	{ "<leader>hD", desc = "Diff This ~" },

	-- AI/Copilot operations
	{ "<leader>a", group = "󰚩 AI/Copilot" },
	{ "<leader>ac", desc = "Open Chat", mode = { "n", "v" } },
	{ "<leader>ae", desc = "Explain Code", mode = { "n", "v" } },
	{ "<leader>af", desc = "Fix Code", mode = { "n", "v" } },
	{ "<leader>ao", desc = "Optimize Code", mode = { "n", "v" } },
	{ "<leader>at", desc = "Generate Tests" },
	{ "<leader>ad", desc = "Generate Docs" },
	{ "<leader>ar", desc = "Review Code", mode = { "n", "v" } },

	-- Code operations
	{ "<leader>c", group = "󰘦 Code" },
	{ "<leader>ca", desc = "Code Actions" },
	{ "<leader>cf", desc = "Quick Fix Diagnostic" },

	-- Diagnostics/Debug
	{ "<leader>d", group = "󰒭 Diagnostics" },
	{ "<leader>ds", desc = "Document Symbols" },

	-- Rename/Refactor
	{ "<leader>r", group = "󰑕 Rename/Refactor" },
	{ "<leader>rn", desc = "Rename Symbol" },

	-- View/Vim operations
	{ "<leader>v", group = "󰈈 View/Vim" },
	{ "<leader>vd", desc = "View Diagnostics Float" },

	-- Workspace/Window
	{ "<leader>w", group = "󰒲 Workspace/Window/Write" },
	{ "<leader>ws", desc = "Workspace Symbols" },

	-- Toggle operations
	{ "<leader>t", group = "󰔡 Toggle" },
	{ "<leader>th", desc = "Toggle Inlay Hints" },
	{ "<leader>tb", desc = "Toggle Line Blame" }, -- GitSigns
	{ "<leader>td", desc = "Toggle Deleted Lines" }, -- GitSigns

	-- Neotree
	{ "<leader>n", group = "󰙅 Neotree" },
	{ "<leader>nb", desc = "Show Buffer List (float)" },

	-- Markdown
	{ "<leader>m", group = " Markdown" },
	{ "<leader>mv", desc = "Toggle Markview" },

	-- Standalone leader keys
	{ "<leader>pv", desc = "Open File Explorer (Ex)" },
	{ "<leader>q", desc = "Close Buffer" },
	{ "<leader>Q", desc = "Quit All" },
	{ "<leader>w", desc = "Save File" },
	{ "<leader>f", desc = "Format Buffer" },
	{ "<leader>u", desc = "Toggle Undo Tree" },
	{ "<leader>R", desc = "󰑓 Reload Neovim Config" },
	{ "<leader>p", desc = "Paste without overwriting register", mode = "x" },
	{ "<leader>y", desc = "Yank to system clipboard", mode = { "n", "v" } },
	{ "<leader>Y", desc = "Yank line to system clipboard" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- CONTROL KEY MAPPINGS
	-- ═══════════════════════════════════════════════════════════════════════════════

	{ "<C-n>", desc = "󰙅 Toggle File Explorer (Neotree)" },
	{ "<C-p>", desc = "󰈞 Find Git Files" },

	-- Window navigation
	{ "<C-h>", desc = "󰁍 Window Left" },
	{ "<C-j>", desc = "󰁅 Window Down" },
	{ "<C-k>", desc = "󰁝 Window Up" },
	{ "<C-l>", desc = "󰁔 Window Right" },

	-- Scrolling with centering
	{ "<C-d>", desc = "󰜮 Scroll Down (centered)" },
	{ "<C-u>", desc = "󰜷 Scroll Up (centered)" },
	{ "<C-f>", desc = "󰜴 Page Down (centered)" },
	{ "<C-b>", desc = "󰜱 Page Up (centered)" },

	-- Insert mode mappings
	{ "<C-c>", desc = "󰿅 Exit Insert Mode", mode = "i" },
	{ "<C-s>", desc = "󰋖 Signature Help", mode = "i" },

	-- Completion mappings (nvim-cmp)
	{ "<C-Space>", desc = "󰄮 Manual Complete", mode = "i" },
	{ "<C-e>", desc = "󰅙 Abort Completion", mode = "i" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- LSP & NAVIGATION
	-- ═══════════════════════════════════════════════════════════════════════════════

	-- LSP operations
	{ "K", desc = "󰋖 Hover Documentation" },
	{ "gd", desc = "󰑊 Go to Definition" },
	{ "gi", desc = "󰑊 Go to Implementation" },
	{ "gt", desc = "󰑊 Go to Type Definition" },
	{ "gr", desc = "󰑊 Go to References" },

	-- Diagnostic navigation
	{ "[d", desc = "󰒕 Previous Diagnostic" },
	{ "]d", desc = "󰒖 Next Diagnostic" },

	-- Git hunk navigation (GitSigns)
	{ "[c", desc = "󰒕 Previous Git Hunk" },
	{ "]c", desc = "󰒖 Next Git Hunk" },

	-- ═══════════════════════════════════════════════════════════════════════════════
	-- TEXT OBJECTS & SPECIAL KEYS
	-- ═══════════════════════════════════════════════════════════════════════════════

	-- Git text objects
	{ "ih", desc = "󰊢 Inner Hunk", mode = { "o", "x" } },

	-- Special keys
	{ "Y", desc = "󰆏 Yank Line" },
	{ "<CR>", desc = "󰄲 Confirm Completion", mode = "i" },
	{ "<Tab>", desc = "󰌒 Next Completion/Expand Snippet", mode = "i" },
	{ "<S-Tab>", desc = "󰌒 Previous Completion/Jump Back", mode = "i" },
})
