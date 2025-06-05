return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",

    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },

    config = function()
      require("telescope").setup({ extensions = { fzf = {} } })

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>en", function()
        builtin.find_files({
          cwd = vim.fn.stdpath("config"),
        })
      end)
      vim.keymap.set("n", "<C-p>", builtin.git_files, {})
      vim.keymap.set("n", "<leader>fw", function()
        local word = vim.fn.expand("<cword>")
        builtin.grep_string({ search = word })
      end)
      vim.keymap.set("n", "<leader>fW", function()
        local word = vim.fn.expand("<cWORD>")
        builtin.grep_string({ search = word })
      end)
      vim.keymap.set("n", "<leader>gw", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})

      vim.keymap.set("n", "<leader>gd", builtin.lsp_definitions, {})
      vim.keymap.set("n", "<leader>gr", builtin.lsp_references, {})

      vim.keymap.set("n", "K", function()
        vim.lsp.buf.hover()
      end, {})
      vim.keymap.set("n", "<leader>vws", function()
        vim.lsp.buf.workspace_symbol()
      end, {})
      vim.keymap.set("n", "<leader>vd", function()
        vim.diagnostic.open_float()
      end, {})
      vim.keymap.set("n", "<leader>ca", function()
        vim.lsp.buf.code_action()
      end, {})
      vim.keymap.set("n", "<leader>rn", function()
        vim.lsp.buf.rename()
      end, {})
      vim.keymap.set("i", "<C-h>", function()
        vim.lsp.buf.signature_help()
      end, {})
      vim.keymap.set("n", "[d", function()
        vim.diagnostic.goto_next()
      end, {})
      vim.keymap.set("n", "]d", function()
        vim.diagnostic.goto_prev()
      end, {})
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },
}
