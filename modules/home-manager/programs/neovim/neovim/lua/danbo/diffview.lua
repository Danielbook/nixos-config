require("diffview").setup({
  enhanced_diff_hl = true,
  view = {
    -- Review flow: two-pane diff. Merge conflicts get the 3-way layout.
    default = { layout = "diff2_horizontal" },
    merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
    file_history = { layout = "diff2_horizontal" },
  },
  file_panel = {
    listing_style = "tree",
    win_config = { position = "left", width = 40 },
  },
})

local map = vim.keymap.set

-- Review the whole change set against a base, commit-by-commit or as one diff.
map("n", "<leader>gv", "<cmd>DiffviewOpen<cr>", { desc = "Diffview: working tree" })
map("n", "<leader>gV", function()
  vim.ui.input({ prompt = "Diffview base: ", default = "origin/main..." }, function(rev)
    if rev and rev ~= "" then
      vim.cmd("DiffviewOpen " .. rev)
    end
  end)
end, { desc = "Diffview: against base" })
map("n", "<leader>gq", "<cmd>DiffviewClose<cr>", { desc = "Diffview: close" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview: file history" })
map("v", "<leader>gh", "<Esc><cmd>'<,'>DiffviewFileHistory<cr>", { desc = "Diffview: range history" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview: branch history" })
