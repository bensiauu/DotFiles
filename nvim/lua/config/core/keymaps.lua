-- Keymaps
vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
vim.api.nvim_set_keymap("n", "<leader>w", ":w<CR>", { noremap = true, silent = true, desc = "Write buffer" })
vim.api.nvim_set_keymap("n", "<C-h>", "<C-w>h", { noremap = true, silent = true, desc = "Switch to Buffer Left" })
vim.api.nvim_set_keymap("n", "<C-j>", "<C-w>j", { noremap = true, silent = true, desc = "Switch to Buffer below" })
vim.api.nvim_set_keymap("n", "<C-k>", "<C-w>k", { noremap = true, silent = true, desc = "Switch to buffer above" })
vim.api.nvim_set_keymap("n", "<C-l>", "<C-w>l", { noremap = true, silent = true, desc = "Switch to buffer right" })

-- <leader>q to force quit all (qa!)
vim.api.nvim_set_keymap("n", "<leader>q", ":qa!<CR>", { noremap = true, silent = true, desc = "Quit NeoVim" })

-- <leader>bk to close the current buffer
vim.api.nvim_set_keymap("n", "<leader>bk", ":bd<CR>", { noremap = true, silent = true, desc = "Buffer Kill" })

-- [b to go to the previous buffer
vim.api.nvim_set_keymap("n", "[b", ":bprev<CR>", { noremap = true, silent = true, desc = "Buffer Previous" })

-- ]b to go to the next buffer
vim.api.nvim_set_keymap("n", "]b", ":bnext<CR>", { noremap = true, silent = true, desc = "Buffer Next" })

-- Toggle line wrapping
vim.keymap.set(
	"n",
	"<leader>lw",
	"<cmd>set wrap!<CR>",
	{ noremap = true, silent = true, desc = "Toggle Line Wrapping" }
)
