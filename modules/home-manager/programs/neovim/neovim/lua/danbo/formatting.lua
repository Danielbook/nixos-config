local null_ls = require("null-ls")
local lsp = require("danbo.lsp")

null_ls.setup({
	on_attach = lsp.on_attach,
	sources = {
		null_ls.builtins.formatting.alejandra,
		null_ls.builtins.formatting.prettier,
		null_ls.builtins.formatting.stylua,
	},
})
