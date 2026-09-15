-- Noctalia dynamic colorscheme via base16
-- Colors are generated from wallpaper by Noctalia and written to matugen.lua
local ok, matugen = pcall(require, 'matugen')
if ok then
  matugen.setup()
else
  -- No Noctalia (macOS, or template not enabled yet): use catppuccin
  vim.cmd.colorscheme('catppuccin-mocha')
end
