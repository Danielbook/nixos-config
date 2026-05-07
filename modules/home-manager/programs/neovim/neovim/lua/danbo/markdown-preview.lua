-- markdown-preview.nvim: browser-based preview supporting mermaid + plantuml
--
-- Diagram blocks:
--   ```mermaid ... ```                native, no server
--   @startuml ... @enduml             via plantuml server (public by default)
--   @startdot ... @enddot             graphviz/DOT, also via plantuml server
vim.g.mkdp_auto_start = 0
vim.g.mkdp_auto_close = 1
vim.g.mkdp_refresh_slow = 0
vim.g.mkdp_browser = ""
vim.g.mkdp_echo_preview_url = 1
vim.g.mkdp_filetypes = { "markdown" }
vim.g.mkdp_theme = "dark"

vim.g.mkdp_preview_options = {
  mkit = {},
  katex = {},
  uml = { server = "https://www.plantuml.com/plantuml" },
  maid = {},
  disable_sync_scroll = 0,
  sync_scroll_type = "middle",
  hide_yaml_meta = 1,
  sequence_diagrams = {},
  flowchart_diagrams = {},
  content_editable = false,
  disable_filename = 0,
  toc = {},
}

