local null_ls = require("null-ls")
local lsp = require("danbo.lsp")

-- Prettier automatically finds and uses project-specific configs
-- (.prettierrc.yaml, .prettierrc.json, etc.)
-- No need to conditionally enable/disable it
local sources = {
	null_ls.builtins.formatting.alejandra,
	null_ls.builtins.formatting.stylua,
	null_ls.builtins.formatting.prettier, -- Always enabled, respects project configs
}

null_ls.setup({
	on_attach = lsp.on_attach,
	sources = sources,
	-- Increase timeout for large files (default is 5000ms)
	-- Set to 30 seconds to handle large file operations
	timeout_ms = 30000,
})
