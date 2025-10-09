-- Nvim-notify configuration for beautiful notifications
require("notify").setup({
  -- Animation style
  stages = "fade_in_slide_out",
  
  -- Timeout for notifications
  timeout = 3000,
  
  -- Background transparency
  background_colour = "#000000",
  
  -- Icons for different log levels
  icons = {
    ERROR = "",
    WARN = "",
    INFO = "",
    DEBUG = "",
    TRACE = "✎",
  },
  
  -- Animation configuration
  fps = 30,
  render = "default",
  
  -- Top down notification flow
  top_down = true,
  
  -- Minimum width
  minimum_width = 50,
  
  -- Maximum width as percentage of screen
  max_width = function()
    return math.floor(vim.o.columns * 0.75)
  end,
  
  -- Maximum height as percentage of screen  
  max_height = function()
    return math.floor(vim.o.lines * 0.75)
  end,
  
  -- Level configuration
  level = vim.log.levels.INFO,
  
  -- Animation timing functions
  on_open = function(win)
    vim.api.nvim_win_set_config(win, { zindex = 100 })
  end,
})

-- Set nvim-notify as the default notification handler
vim.notify = require("notify")