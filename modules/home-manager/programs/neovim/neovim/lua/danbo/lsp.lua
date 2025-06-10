local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local M = {}

M.on_attach = function(client, bufnr)
	if client.supports_method("textDocument/formatting") then
		local group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = false })
		vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })

		vim.api.nvim_create_autocmd("BufWritePre", {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({
					bufnr = bufnr,
					filter = function(c)
						return c.name == "null-ls" or c.name == "none-ls"
					end,
				})
			end,
		})
	end
end

-- Your LSP servers setup here
local servers = {
	lua_ls = {},
	html = {},
	ts_ls = {},
	gopls = {},
	tailwindcss = {},
	nil_ls = {},
}

for name, config in pairs(servers) do
	lspconfig[name].setup(vim.tbl_deep_extend("force", {
		capabilities = capabilities,
		on_attach = M.on_attach,
	}, config))
end

return M
