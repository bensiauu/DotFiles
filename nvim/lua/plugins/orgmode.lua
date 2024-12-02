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
            org_toggle_checkbox = "<leader>otc", -- Map your preferred keybinding
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
        directory = "~/Documents/Ben_Ideaverse/org/roam/",
        -- optional
        org_files = {
          "~/Documents/Ben_Ideaverse/org/projects/*.org",
          "~/Documents/Ben_Ideaverse/org/agendas/*.org",
        },
      })
    end,
  },
}
