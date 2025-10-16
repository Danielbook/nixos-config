local capabilities = require("cmp_nvim_lsp").default_capabilities()

local M = {}

local function on_attach(client, bufnr)
	-- Disable inlay hints by default (use <leader>th to toggle)
	if client.supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
	end

	-- Enable document highlight (highlight other uses of symbol under cursor)
	if client.supports_method("textDocument/documentHighlight") then
		local group = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = false })
		vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			group = group,
			buffer = bufnr,
			callback = vim.lsp.buf.document_highlight,
		})
		vim.api.nvim_create_autocmd("CursorMoved", {
			group = group,
			buffer = bufnr,
			callback = vim.lsp.buf.clear_references,
		})
	end

	-- Format on save with any LSP that supports it
	if client.supports_method("textDocument/formatting") then
		local group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = false })
		vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })

		vim.api.nvim_create_autocmd("BufWritePre", {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end,
		})
	end

	-- Enable codelens if supported
	if client.supports_method("textDocument/codeLens") then
		vim.lsp.codelens.refresh()
		local group = vim.api.nvim_create_augroup("LspCodeLens", { clear = false })
		vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
		vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
			group = group,
			buffer = bufnr,
			callback = vim.lsp.codelens.refresh,
		})
	end
end

-- Configure and enable LSP servers using vim.lsp.config (Neovim 0.11+)
local servers = {
	lua_ls = {
		settings = {
			Lua = {
				hint = {
					enable = true,
				},
				runtime = {
					version = "LuaJIT",
				},
				diagnostics = {
					globals = { "vim" },
				},
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
				telemetry = {
					enable = false,
				},
			},
		},
	},
	html = {},
	ts_ls = {
		settings = {
			typescript = {
				inlayHints = {
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayEnumMemberValueHints = true,
				},
				suggest = {
					includeCompletionsForModuleExports = true,
					includeAutomaticOptionalChainCompletions = true,
				},
				preferences = {
					includePackageJsonAutoImports = "auto",
					importModuleSpecifierPreference = "relative",
					quotePreference = "auto",
				},
				updateImportsOnFileMove = {
					enabled = "always",
				},
			},
			javascript = {
				inlayHints = {
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayEnumMemberValueHints = true,
				},
				suggest = {
					includeCompletionsForModuleExports = true,
					includeAutomaticOptionalChainCompletions = true,
				},
				preferences = {
					includePackageJsonAutoImports = "auto",
					importModuleSpecifierPreference = "relative",
					quotePreference = "auto",
				},
				updateImportsOnFileMove = {
					enabled = "always",
				},
			},
		},
	},
	gopls = {
		settings = {
			gopls = {
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					compositeLiteralTypes = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
			},
		},
	},
	tailwindcss = {},
	nil_ls = {},
	nixd = {
		settings = {
			nixd = {
				nixpkgs = {
					expr = "import <nixpkgs> { }",
				},
				formatting = {
					command = { "alejandra" },
				},
			},
		},
	},
}

for name, config in pairs(servers) do
	vim.lsp.config(name, vim.tbl_deep_extend("force", {
		capabilities = capabilities,
		on_attach = on_attach,
	}, config))
	vim.lsp.enable(name)
end

return M
