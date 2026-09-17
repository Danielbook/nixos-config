-- Loaded first so MiniIcons.mock_nvim_web_devicons() registers before any
-- plugin (lualine, alpha, telescope, neo-tree, noice) resolves devicons.
require("danbo.mini-modules")

require("danbo.alpha")
require("danbo.catppuccin")
require("danbo.cmp")
require("danbo.copilot")
require("danbo.copilot-chat")
require("danbo.diagnostics")
require("danbo.gitsigns")
require("danbo.hardtime")
require("danbo.lsp")
require("danbo.formatting")
require("danbo.precognition")
require("danbo.treesitter")
require("danbo.ts-autotag")
require("danbo.telescope")
require("danbo.lualine")
require("danbo.markview")
require("danbo.markdown-preview")
require("danbo.remap")
-- After remap: mapleader is set there, and diffview registers <leader> maps.
require("danbo.diffview")
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
