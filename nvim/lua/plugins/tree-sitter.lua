-- Return the plugin configuration for Lazy.nvim
return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate", -- Ensure parsers are kept up-to-date
    config = function()
      require("nvim-treesitter.configs").setup({
        -- List of languages to install (add/remove languages as needed)
        ensure_installed = { "go", "norg", "lua", "python", "javascript", "html", "css" },

        -- Enable highlighting powered by Treesitter
        highlight = {
          enable = true, -- Enable Treesitter-based syntax highlighting
          additional_vim_regex_highlighting = false, -- Disable Vim regex highlighting
        },

        -- Enable incremental selection based on Treesitter
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
          },
        },

        -- Enable Treesitter-based indentation
        indent = {
          enable = true,
        },
      })
    end,
  },
}
