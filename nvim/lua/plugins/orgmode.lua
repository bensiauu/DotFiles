return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      -- Setup orgmode
      require("orgmode").setup({
        org_agenda_files = "~/org/agendas/*",
        org_default_notes_file = "~/org/roam/",
      })
      vim.keymap.set(
        "n",
        "<leader>oa",
        "<cmd>lua require('orgmode').action('agenda.prompt')<CR>",
        { desc = "Open Org Agenda" }
      )
    end,
  },
  {

    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = "all"
      opts.ignore_install = { "org" }
    end,
  },
}
