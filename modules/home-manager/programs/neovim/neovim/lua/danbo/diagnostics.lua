-- Configure better diagnostics display
vim.diagnostic.config({
	virtual_text = {
		severity = { min = vim.diagnostic.severity.WARN },
		source = "if_many",
		format = function(diagnostic)
			if diagnostic.severity == vim.diagnostic.severity.ERROR then
				return "󰅚 " .. diagnostic.message
			elseif diagnostic.severity == vim.diagnostic.severity.WARN then
				return "󰀪 " .. diagnostic.message
			elseif diagnostic.severity == vim.diagnostic.severity.INFO then
				return "󰋽 " .. diagnostic.message
			elseif diagnostic.severity == vim.diagnostic.severity.HINT then
				return "󰌶 " .. diagnostic.message
			end
		end,
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚",
			[vim.diagnostic.severity.WARN] = "󰀪",
			[vim.diagnostic.severity.INFO] = "󰋽",
			[vim.diagnostic.severity.HINT] = "󰌶",
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		focusable = false,
		style = "minimal",
		border = "rounded",
		source = "always",
		header = "",
		prefix = "",
		format = function(diagnostic)
			local code = diagnostic.code or diagnostic.user_data and diagnostic.user_data.lsp.code
			if code then
				return string.format("%s [%s]", diagnostic.message, code)
			end
			return diagnostic.message
		end,
	},
})