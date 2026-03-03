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

	-- CodeLens disabled for performance (was causing slowness in vtsls)
	-- if client.supports_method("textDocument/codeLens") then
	-- 	vim.lsp.codelens.refresh()
	-- 	local group = vim.api.nvim_create_augroup("LspCodeLens", { clear = false })
	-- 	vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
	-- 	vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
	-- 		group = group,
	-- 		buffer = bufnr,
	-- 		callback = vim.lsp.codelens.refresh,
	-- 	})
	-- end
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
	vtsls = {
		settings = {
			typescript = {
				inlayHints = {
					parameterNames = { enabled = "all" },
					parameterTypes = { enabled = true },
					variableTypes = { enabled = true },
					propertyDeclarationTypes = { enabled = true },
					functionLikeReturnTypes = { enabled = true },
					enumMemberValues = { enabled = true },
				},
				suggest = {
					completeFunctionCalls = true,
				},
				preferences = {
					importModuleSpecifier = "relative",
					quoteStyle = "auto",
				},
				updateImportsOnFileMove = { enabled = "always" },
				referencesCodeLens = {
					enabled = false,
				},
				implementationsCodeLens = {
					enabled = false,
				},
			},
			javascript = {
				inlayHints = {
					parameterNames = { enabled = "all" },
					parameterTypes = { enabled = true },
					variableTypes = { enabled = true },
					propertyDeclarationTypes = { enabled = true },
					functionLikeReturnTypes = { enabled = true },
					enumMemberValues = { enabled = true },
				},
				suggest = {
					completeFunctionCalls = true,
				},
				preferences = {
					importModuleSpecifier = "relative",
					quoteStyle = "auto",
				},
				updateImportsOnFileMove = { enabled = "always" },
				referencesCodeLens = {
					enabled = false,
				},
				implementationsCodeLens = {
					enabled = false,
				},
			},
			vtsls = {
				autoUseWorkspaceTsdk = true,
			},
		},
	},
	gopls = {
		filetypes = { "go", "gomod", "gowork", "gotmpl" },
		root_markers = { "go.work", "go.mod", ".git" },
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
				codelenses = {
					gc_details = false,
					generate = true,
					regenerate_cgo = true,
					run_govulncheck = true,
					test = true,
					tidy = true,
					upgrade_dependency = true,
					vendor = true,
				},
			},
		},
	},
	rust_analyzer = {
		filetypes = { "rust" },
		root_markers = { "Cargo.toml", "rust-project.json" },
		settings = {
			["rust-analyzer"] = {
				inlayHints = {
					chainingHints = { enable = true },
					parameterHints = { enable = true },
					typeHints = { enable = true },
					closingBraceHints = { enable = true },
				},
				check = {
					command = "clippy",
				},
			},
		},
	},
	pyright = {
		filetypes = { "python" },
		root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
		settings = {
			python = {
				analysis = {
					autoSearchPaths = true,
					useLibraryCodeForTypes = true,
					diagnosticMode = "openFilesOnly",
				},
			},
		},
	},
	biome = {},
	svelte = {},
	eslint = {},
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
