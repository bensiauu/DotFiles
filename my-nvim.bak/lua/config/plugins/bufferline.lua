return {
  'akinsho/bufferline.nvim',
  version = "*",
  dependencies = {
    'nvim-tree/nvim-web-devicons', -- For file icons
  },
  config = function()
    require("bufferline").setup({
      options = {
        mode = "buffers", -- Use buffers mode
        numbers = "none", -- No numbers on buffer tabs
        close_command = "Bdelete! %d", -- Command to close buffer
        right_mouse_command = "Bdelete! %d", -- Right-click to close buffer
        diagnostics = "none", -- Optionally show diagnostics
        separator_style = "slant", -- You can choose 'slant', 'thick', 'thin'
        always_show_bufferline = true, -- Show bufferline even with a single buffer
        themeable = true, -- Allow for theme customization
	modified_icon = '●',
      },
      highlights = {
        fill = {
          guifg = {attribute = "fg", highlight = "TabLine"},
          guibg = {attribute = "bg", highlight = "TabLine"},
        },
        background = {
          guifg = {attribute = "fg", highlight = "TabLine"},
          guibg = {attribute = "bg", highlight = "TabLine"},
        },
        buffer_selected = {
          guifg = {attribute = "fg", highlight = "Normal"},
          guibg = {attribute = "bg", highlight = "Normal"},
          gui = "bold",
        },
        separator_selected = {
          guifg = {attribute = "bg", highlight = "Normal"},
          guibg = {attribute = "bg", highlight = "Normal"},
        },
	modified = {
          guifg = "#e06c75", -- Color for unsaved icon
          guibg = {attribute = "bg", highlight = "TabLine"},
        },
        modified_selected = {
          guifg = "#e06c75", -- Color for unsaved icon in selected buffer
          guibg = {attribute = "bg", highlight = "Normal"},
        },
      },
    })
  end,
}
