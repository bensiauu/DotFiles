vim.g.mapleader = " "
vim.g.maplocalleader = ","

local keymap = vim.keymap
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- open file_browser with the path of the current buffer
vim.keymap.set("n", "<space>fb", ":Telescope file_browser path=%:p:h select_buffer=true<CR>")

-- Common Neovim key mappings for plugin functionality
vim.api.nvim_set_keymap("n", "<leader>q", ":q<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>w", ":w<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>e", ":e<CR>", { noremap = true, silent = true })

-- Noice plugin mappings
vim.api.nvim_set_keymap("n", "<leader>no", ":Noice<CR>", { noremap = true, silent = true })

-- vim- fugitive key mappings
vim.api.nvim_set_keymap("n", "<leader>gt", "<cmd>G<CR>", { noremap = true, silent = true })

-- Oil
vim.api.nvim_set_keymap("n", "<leader>e", ":Oil<CR>", { noremap = true, silent = true })
