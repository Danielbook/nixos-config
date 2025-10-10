local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local M = {}

M.on_attach = function(client, bufnr)
	-- Enable inlay hints if supported
	if client.supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
	end

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
	lua_ls = {
		settings = {
			Lua = {
				hint = {
					enable = true,
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
				options = {
					nixos = {
						expr = '(builtins.getFlake "/home/daniel/Documents/repositories/nixos-config").nixosConfigurations.danbo.options',
					},
					home_manager = {
						expr = '(builtins.getFlake "/home/daniel/Documents/repositories/nixos-config").homeConfigurations."daniel@danbo".options',
					},
				},
			},
		},
	},
}

for name, config in pairs(servers) do
	lspconfig[name].setup(vim.tbl_deep_extend("force", {
		capabilities = capabilities,
		on_attach = M.on_attach,
	}, config))
end

return M
