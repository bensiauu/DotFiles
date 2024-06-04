vim.g.mapleader = ' '

local keymap = vim.keymap
keymap.set("i", "jk", '<ESC>', {desc="Exit insert mode with jj"})

-- open file_browser with the path of the current buffer
vim.keymap.set("n", "<space>fb", ":Telescope file_browser path=%:p:h select_buffer=true<CR>")

-- Common Neovim key mappings for plugin functionality
vim.api.nvim_set_keymap('n', '<leader>q', ':q<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>w', ':w<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>e', ':e<CR>', { noremap = true, silent = true })

-- Noice plugin mappings
vim.api.nvim_set_keymap('n', '<leader>no', ':Noice<CR>', { noremap = true, silent = true })

-- Nvim Tree plugin mappings
vim.api.nvim_set_keymap('n', '<leader>nt', ':NvimTreeToggle<CR>', { noremap = true, silent = true })


-- vim- fugitive key mappings
vim.api.nvim_set_keymap('n', '<leader>gt', '<cmd>G<CR>', {noremap = true, silent = true})

