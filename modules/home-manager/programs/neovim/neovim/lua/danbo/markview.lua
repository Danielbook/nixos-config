require("markview").setup({
  -- Hybrid mode: render on non-cursor line, show raw markdown on cursor line
  modes = { "n", "no", "c" },
  hybrid_modes = { "n" },

  callbacks = {
    on_enable = function(_, win)
      vim.wo[win].conceallevel = 2
      vim.wo[win].concealcursor = "c"
    end,
  },
})
