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
keymap("n", "<c-k>", ":wincmd k<CR>")
keymap("n", "<c-j>", ":wincmd j<CR>")
keymap("n", "<c-h>", ":wincmd h<CR>")
keymap("n", "<c-l>", ":wincmd l<CR>")

keymap("i", "<C-c>", "<Esc>")

-- Save and quit
keymap("n", "<leader>w", ":w<CR>", opts)
keymap("n", "<leader>q", ":q<CR>", opts)

-- Paste over selection without overwriting the default register
-- Deletes selected text to the black hole register, then pastes
keymap("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
keymap({ "n", "v" }, "<leader>y", [["+y]])
keymap("n", "<leader>Y", [["+Y]])

-- Neotree
keymap("n", "<C-n>", "<cmd>Neotree filesystem reveal left<CR>")
keymap("n", "<leader>bf", "<cmd>Neotree buffers reveal float<CR>")

-- Telescope
local telescope = require("telescope.builtin")
keymap("n", "<leader>ff", telescope.find_files)
keymap("n", "<leader>en", function()
 telescope.find_files({
   cwd = vim.fn.stdpath("config"),
 })
end)
keymap("n", "<C-p>", telescope.git_files, opts)
keymap("n", "<leader>fw", function()
 local word = vim.fn.expand("<cword>")
 telescope.grep_string({ search = word })
end)
keymap("n", "<leader>fW", function()
 local word = vim.fn.expand("<cWORD>")
 telescope.grep_string({ search = word })
end)
keymap("n", "<leader>gw", telescope.live_grep, opts)
keymap("n", "<leader>fh", telescope.help_tags, opts)

keymap("n", "<leader>gd", telescope.lsp_definitions, opts)
keymap("n", "<leader>gr", telescope.lsp_references, opts)

-- LSP
keymap("n", "K", function()
 vim.lsp.buf.hover()
end, {})
keymap("n", "<leader>vws", function()
 vim.lsp.buf.workspace_symbol()
end, {})
keymap("n", "<leader>vd", function()
 vim.diagnostic.open_float()
end, {})
keymap("n", "<leader>ca", function()
 vim.lsp.buf.code_action()
end, {})
keymap("n", "<leader>rn", function()
 vim.lsp.buf.rename()
end, {})
keymap("i", "<C-h>", function()
 vim.lsp.buf.signature_help()
end, {})
keymap("n", "[d", function()
 vim.diagnostic.goto_next()
end, {})
keymap("n", "]d", function()
 vim.diagnostic.goto_prev()
end, {})

keymap("n", "<leader>fb", vim.lsp.buf.format)
keymap("n", "<leader>u", vim.cmd.UndotreeToggle)
 
