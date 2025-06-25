return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim", -- required
    "sindrets/diffview.nvim", -- optional - Diff integration

    -- Only one of these is needed.
    "nvim-telescope/telescope.nvim", -- optional
  },
  config = function()
    -- Set up Neogit options for a floating window
    require("neogit").setup({
      integrations = {
        -- Optional: You can add more integrations here if needed
      },
      kind = "floating", -- Set the window kind to floating
    })

    -- Custom key mapping to open Neogit in a floating window
    vim.keymap.set("n", "<Leader>gg", ":Neogit<CR>", { noremap = true, silent = true })
  end,
}
