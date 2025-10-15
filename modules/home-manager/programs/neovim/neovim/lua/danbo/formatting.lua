local null_ls = require("null-ls")
local lsp = require("danbo.lsp")

-- Helper function to check if a file exists
local function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

-- Check if project has its own formatter config
local function has_project_formatter()
	local cwd = vim.fn.getcwd()
	local prettier_configs = {
		".prettierrc",
		".prettierrc.json",
		".prettierrc.yml",
		".prettierrc.yaml",
		".prettierrc.js",
		".prettierrc.cjs",
		"prettier.config.js",
		"prettier.config.cjs",
	}
	local eslint_configs = {
		".eslintrc",
		".eslintrc.json",
		".eslintrc.yml",
		".eslintrc.yaml",
		".eslintrc.js",
		".eslintrc.cjs",
		"eslint.config.js",
	}

	-- Check for prettier config
	for _, config in ipairs(prettier_configs) do
		if file_exists(cwd .. "/" .. config) then
			return true, "prettier"
		end
	end

	-- Check for eslint config
	for _, config in ipairs(eslint_configs) do
		if file_exists(cwd .. "/" .. config) then
			return true, "eslint"
		end
	end

	-- Check package.json for prettier or eslint config
	local package_json = cwd .. "/package.json"
	if file_exists(package_json) then
		local f = io.open(package_json, "r")
		if f then
			local content = f:read("*all")
			f:close()
			if content:match('"prettier"') or content:match('"eslint"') then
				return true, "package.json"
			end
		end
	end

	return false, nil
end

-- Only use null-ls prettier if project doesn't have its own config
local sources = {
	null_ls.builtins.formatting.alejandra,
	null_ls.builtins.formatting.stylua,
}

local has_formatter, formatter_type = has_project_formatter()
if not has_formatter then
	-- Only add prettier if no project-specific config exists
	table.insert(sources, null_ls.builtins.formatting.prettier)
end

null_ls.setup({
	on_attach = lsp.on_attach,
	sources = sources,
})
