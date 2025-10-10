require("danbo.alpha")
require("danbo.catppuccin")
require("danbo.cmp")
require("danbo.diagnostics")
require("danbo.gitsigns")
require("danbo.lsp")
require("danbo.formatting")
require("danbo.treesitter")
require("danbo.ts-autotag")
require("danbo.telescope")
require("danbo.lualine")
require("danbo.remap")
require("danbo.set")
require("danbo.which-key")

-- Animation configurations for smooth UI experience
-- Load with pcall to handle missing files gracefully
local ok, _ = pcall(require, "danbo.notify")
if ok then
  local ok2, _ = pcall(require, "danbo.noice")
  if ok2 then
    pcall(require, "danbo.mini-animate")
    pcall(require, "danbo.indent-blankline")
  end
end
