vim.g.mapleader = " "
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap("n", "<leader>pv", vim.cmd.Ex)

-- Center down and up command
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "<C-f>", "<C-f>zz")
keymap("n", "<C-b>", "<C-b>zz")
keymap("n", "Y", "yy")

-- Navigate vim panes better
keymap("n", "<C-k>", ":wincmd k<CR>")
keymap("n", "<C-j>", ":wincmd j<CR>")
keymap("n", "<C-h>", ":wincmd h<CR>")
keymap("n", "<C-l>", ":wincmd l<CR>")

keymap("i", "<C-c>", "<Esc>")

-- Save and quit
keymap("n", "<leader>w", ":w<CR>", { desc = "Save file" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- Insert blank lines above/below without leaving current line
keymap("n", "[<Space>", "O<Esc>j", { desc = "Add blank line above" })
keymap("n", "]<Space>", "o<Esc>k", { desc = "Add blank line below" })

-- Paste over selection without overwriting the default register
-- Deletes selected text to the black hole register, then pastes
keymap("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
keymap({ "n", "v" }, "<leader>y", [["+y]])
keymap("n", "<leader>Y", [["+Y]])

-- Neotree
keymap("n", "<C-n>", "<cmd>Neotree filesystem reveal left<CR>", { desc = "Toggle file explorer" })
keymap("n", "<leader>nb", "<cmd>Neotree buffers reveal float<CR>", { desc = "Show buffer list" })

-- Telescope
local telescope = require("telescope.builtin")
keymap("n", "<leader>ff", telescope.find_files)
keymap("n", "<leader>fb", telescope.buffers)
keymap("n", "<C-p>", telescope.git_files, opts)
keymap("n", "<leader>fw", function()
	local word = vim.fn.expand("<cword>")
	telescope.grep_string({ search = word })
end)
keymap("n", "<leader>fW", function()
	local word = vim.fn.expand("<cWORD>")
	telescope.grep_string({ search = word })
end)
keymap("n", "<leader>sg", telescope.live_grep, opts)
keymap("n", "<leader>fh", telescope.help_tags, opts)

-- Fugitive (Git commands)
keymap("n", "<leader>gs", "<cmd>Git<CR>", { desc = "Git status" })
keymap("n", "<leader>gc", "<cmd>Git commit<CR>", { desc = "Git commit" })
keymap("n", "<leader>gp", "<cmd>Git push<CR>", { desc = "Git push" })
keymap("n", "<leader>gP", "<cmd>Git pull<CR>", { desc = "Git pull" })
keymap("n", "<leader>gb", "<cmd>Git blame<CR>", { desc = "Git blame" })
keymap("n", "<leader>gd", "<cmd>Gdiffsplit<CR>", { desc = "Git diff" })
keymap("n", "<leader>gl", "<cmd>Git log<CR>", { desc = "Git log" })
keymap("n", "<leader>gL", "<cmd>Git log %<CR>", { desc = "Git log (current file)" })
keymap("n", "<leader>gr", "<cmd>Gread<CR>", { desc = "Git read (checkout file)" })
keymap("n", "<leader>gw", "<cmd>Gwrite<CR>", { desc = "Git write (stage file)" })

-- LSP (prefer Telescope versions for fuzzy finding)
keymap("n", "K", function()
	vim.lsp.buf.hover()
end, {})
keymap("n", "gd", telescope.lsp_definitions, opts)
keymap("n", "gi", function()
	vim.lsp.buf.implementation()
end, {})
keymap("n", "gt", function()
	vim.lsp.buf.type_definition()
end, {})
keymap("n", "gr", function()
	require("telescope.builtin").lsp_references({
		include_declaration = false,
		file_ignore_patterns = {},
		entry_maker = function(entry)
			local make_entry = require("telescope.make_entry")
			local default_entry = make_entry.gen_from_quickfix()(entry)

			if default_entry and default_entry.text then
				local text = default_entry.text
				-- Filter out import lines
				if text:match("^%s*import%s")
					or text:match("^%s*from%s")
					or text:match("^%s*require%s*%(")
					or text:match("import%s*{.*}%s*from")
					or text:match("import%s*%*%s*as") then
					return nil
				end
			end

			return default_entry
		end,
	})
end, opts)
keymap("n", "<leader>ds", telescope.lsp_document_symbols, opts)
keymap("n", "<leader>ws", telescope.lsp_workspace_symbols, opts)
keymap("n", "<leader>vd", function()
	vim.diagnostic.open_float()
end, {})
keymap("n", "<leader>ca", function()
	vim.lsp.buf.code_action()
end, {})

-- Quick fix for diagnostic at cursor
keymap("n", "<leader>cf", function()
	vim.lsp.buf.code_action({
		filter = function(action)
			return action.isPreferred
		end,
		apply = true,
	})
end, { desc = "Quick fix diagnostic" })
keymap("n", "<leader>rn", function()
	vim.lsp.buf.rename()
end, {})
keymap("i", "<C-s>", function()
	vim.lsp.buf.signature_help()
end, {})
keymap("n", "[d", function()
	vim.diagnostic.goto_prev()
end, {})
keymap("n", "]d", function()
	vim.diagnostic.goto_next()
end, {})
keymap("n", "<leader>th", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })
keymap("n", "<leader>f", vim.lsp.buf.format)
keymap("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle undo tree" })

-- CodeLens
keymap("n", "<leader>cl", function()
	vim.lsp.codelens.run()
end, { desc = "Run CodeLens action" })
keymap("n", "<leader>cr", function()
	vim.lsp.codelens.refresh()
end, { desc = "Refresh CodeLens" })

-- Reload configuration
keymap("n", "<leader>R", function()
	-- Clear the module cache for your config
	for name, _ in pairs(package.loaded) do
		if name:match("^danbo") then
			package.loaded[name] = nil
		end
	end
	-- Reload the main config
	dofile(vim.env.MYVIMRC)
	vim.notify("Configuration reloaded!", vim.log.levels.INFO)
end, { desc = "Reload Neovim config" })

-- Add fuzzy search as separate key
keymap({ "n", "v" }, "<leader>/", function()
	local default_text = ""

	-- If in visual mode, get the selected text
	if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
		-- Get the selected text
		vim.cmd('noau normal! "vy"')
		default_text = vim.fn.getreg("v")
		-- Exit visual mode
		vim.cmd("normal! <Esc>")
	end

	require("telescope.builtin").current_buffer_fuzzy_find(
		vim.tbl_extend("force", require("telescope.themes").get_ivy(), { default_text = default_text })
	)
end, { desc = "Fuzzy search in buffer" })

-- Visual mode search for selected text
keymap("v", "*", function()
	-- Get the selected text
	vim.cmd('noau normal! "vy"')
	local selected_text = vim.fn.getreg("v")
	-- Exit visual mode
	vim.cmd("normal! <Esc>")
	-- Search for the selected text
	vim.fn.setreg("/", "\\V" .. vim.fn.escape(selected_text, "\\"))
	vim.cmd("normal! n")
end, { desc = "Search selected text" })

-- Visual mode: search with selected text
keymap("v", "/", function()
	-- Get the selected text
	vim.cmd('noau normal! "vy"')
	local selected_text = vim.fn.getreg("v")
	-- Exit visual mode and start search with selected text
	vim.cmd("normal! <Esc>")
	vim.fn.feedkeys("/" .. vim.fn.escape(selected_text, "/\\"))
end, { desc = "Search selected text" })

-- Copilot Chat
keymap("n", "<leader>ac", "<cmd>CopilotChat<CR>", { desc = "Open Copilot Chat" })
keymap("v", "<leader>ac", "<cmd>CopilotChat<CR>", { desc = "Open Copilot Chat with selection" })
keymap("n", "<leader>ae", "<cmd>CopilotChatExplain<CR>", { desc = "Explain code" })
keymap("v", "<leader>ae", "<cmd>CopilotChatExplain<CR>", { desc = "Explain selected code" })
keymap("n", "<leader>af", "<cmd>CopilotChatFix<CR>", { desc = "Fix code" })
keymap("v", "<leader>af", "<cmd>CopilotChatFix<CR>", { desc = "Fix selected code" })
keymap("n", "<leader>ao", "<cmd>CopilotChatOptimize<CR>", { desc = "Optimize code" })
keymap("v", "<leader>ao", "<cmd>CopilotChatOptimize<CR>", { desc = "Optimize selected code" })
keymap("n", "<leader>at", "<cmd>CopilotChatTests<CR>", { desc = "Generate tests" })
keymap("n", "<leader>ad", "<cmd>CopilotChatDocs<CR>", { desc = "Generate docs" })
keymap("n", "<leader>ar", "<cmd>CopilotChatReview<CR>", { desc = "Review code" })
keymap("v", "<leader>ar", "<cmd>CopilotChatReview<CR>", { desc = "Review selected code" })

-- Hardtime
keymap("n", "<leader>ht", "<cmd>Hardtime toggle<CR>", { desc = "Toggle Hardtime" })
keymap("n", "<leader>hr", "<cmd>Hardtime report<CR>", { desc = "Hardtime Report" })

-- Precognition
keymap("n", "<leader>pt", "<cmd>Precognition toggle<CR>", { desc = "Toggle Precognition hints" })
keymap("n", "<leader>pp", "<cmd>Precognition peek<CR>", { desc = "Peek Precognition hints" })

-- Gitsigns (buffer-local keymaps set on attach)
vim.api.nvim_create_autocmd("User", {
	pattern = "GitSignsAttach",
	callback = function(args)
		local bufnr = args.buf
		local gs = package.loaded.gitsigns

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- Navigation
		map("n", "]c", function()
			if vim.wo.diff then
				return "]c"
			end
			vim.schedule(function()
				gs.next_hunk()
			end)
			return "<Ignore>"
		end, { expr = true, desc = "Next hunk" })

		map("n", "[c", function()
			if vim.wo.diff then
				return "[c"
			end
			vim.schedule(function()
				gs.prev_hunk()
			end)
			return "<Ignore>"
		end, { expr = true, desc = "Previous hunk" })

		-- Actions
		map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
		map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
		map("v", "<leader>hs", function()
			gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, { desc = "Stage hunk" })
		map("v", "<leader>hr", function()
			gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, { desc = "Reset hunk" })
		map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
		map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
		map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
		map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
		map("n", "<leader>hb", function()
			gs.blame_line({ full = true })
		end, { desc = "Blame line" })
		map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle line blame" })
		map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
		map("n", "<leader>hD", function()
			gs.diffthis("~")
		end, { desc = "Diff this ~" })
		map("n", "<leader>td", gs.toggle_deleted, { desc = "Toggle deleted" })

		-- Text object
		map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
	end,
})
