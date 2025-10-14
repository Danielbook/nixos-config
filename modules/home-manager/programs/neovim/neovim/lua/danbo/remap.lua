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
keymap("n", "gr", telescope.lsp_references, opts)
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
