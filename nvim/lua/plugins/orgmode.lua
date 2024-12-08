return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      -- Setup orgmode
      require("orgmode").setup({
        org_agenda_files = "~/Documents/Ben_Ideaverse/org/agendas/*",
        org_default_notes_file = "~/Documents/Ben_Ideaverse/org/agendas/inbox.org",
        mappings = {
          org = {
            org_toggle_checkbox = "<leader>oc",
          },
        },
      })
    end,
  },
  {
    "akinsho/org-bullets.nvim",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      require("org-bullets").setup()
    end,
  },
}
