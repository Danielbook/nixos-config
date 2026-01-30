-- Noctalia dynamic colorscheme via base16
-- Colors are generated from wallpaper by Noctalia and written to matugen.lua
local ok, matugen = pcall(require, 'matugen')
if ok then
  matugen.setup()
else
  -- Fallback: if matugen.lua doesn't exist yet, use a default base16 theme
  vim.notify("Noctalia colors not generated yet. Enable nvim-base16 template in Noctalia.", vim.log.levels.WARN)
end
