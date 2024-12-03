return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      -- Setup orgmode
      require("orgmode").setup({
        org_agenda_files = "/Users/bensiau/Library/Mobile Documents/com~apple~CloudDocs/org/agendas/*",
        org_default_notes_file = "/Users/bensiau/Library/Mobile Documents/com~apple~CloudDocs/org/agendas/inbox.org",
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
  {
    "chipsenkbeil/org-roam.nvim",
    tag = "0.1.1",
    dependencies = {
      {
        "nvim-orgmode/orgmode",
        tag = "0.3.7",
      },
    },
    config = function()
      require("org-roam").setup({
        directory = "/Users/bensiau/Library/Mobile Documents/com~apple~CloudDocs/org/org/roam/",
        -- optional
        org_files = {
          "/Users/bensiau/Library/Mobile Documents/com~apple~CloudDocs/org/projects/*.org",
          "/Users/bensiau/Library/Mobile Documents/com~apple~CloudDocs/org/agendas/*.org",
        },
      })
    end,
  },
}
