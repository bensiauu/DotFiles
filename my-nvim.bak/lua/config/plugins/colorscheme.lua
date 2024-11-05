return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {},
  config = function()
      -- Set the colorscheme after the plugin is loaded
      vim.cmd("colorscheme tokyonight-moon")
    end,
}
