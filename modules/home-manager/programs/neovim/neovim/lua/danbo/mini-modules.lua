-- mini.icons: drop-in upgrade for nvim-web-devicons (lazy-loaded, font-graceful)
-- The mock makes `require("nvim-web-devicons")` resolve to mini.icons,
-- so consumers (lualine, telescope, neo-tree, alpha, noice) keep working.
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

-- mini.ai: smarter a/i text objects
--   daa / cia  - around / inside argument (e.g. foo(x, |y|, z))
--   daf / cif  - around / inside function call
--   cin"       - change inside the NEXT quote (no jumping first)
--   dil)       - delete inside the LAST parens
require("mini.ai").setup()

-- mini.surround: add/delete/replace surrounding pairs
--   sa{motion}{char}  - surround Add (e.g. saiw"  -> "word")
--   sd{char}          - surround Delete
--   sr{old}{new}      - surround Replace
require("mini.surround").setup()

-- mini.bracketed: uniform [/] navigation across many targets
--   [b/]b buffer, [q/]q quickfix, [l/]l loclist, [j/]j jumplist,
--   [o/]o oldfile, [w/]w window, [t/]t treesitter, [i/]i indent,
--   [d/]d diagnostic, [x/]x diff hunk, [u/]u undo, [f/]f file
-- `comment` is disabled to avoid clashing with gitsigns' [c/]c (git hunks).
require("mini.bracketed").setup({
  comment = { suffix = "" },
})
