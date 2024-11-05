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
vim.api.nvim_set_keymap("n", "<leader>bp", ":bprev<CR>", { noremap = true, silent = true, desc = "Buffer Previous" })

-- ]b to go to the next buffer
vim.api.nvim_set_keymap("n", "<leader>bn", ":bnext<CR>", { noremap = true, silent = true, desc = "Buffer Next" })

-- Toggle line wrapping
vim.keymap.set(
	"n",
	"<leader>lw",
	"<cmd>set wrap!<CR>",
	{ noremap = true, silent = true, desc = "Toggle Line Wrapping" }
)

vim.keymap.set("n", "gk", function()
	-- `?` - Start a search backwards from the current cursor position.
	-- `^` - Match the beginning of a line.
	-- `##` - Match 2 ## symbols
	-- `\\+` - Match one or more occurrences of prev element (#)
	-- `\\s` - Match exactly one whitespace character following the hashes
	-- `.*` - Match any characters (except newline) following the space
	-- `$` - Match extends to end of line
	vim.cmd("silent! ?^##\\+\\s.*$")
	-- Clear the search highlight
	vim.cmd("nohlsearch")
end, { desc = "Go to previous markdown header" })

vim.keymap.set("n", "gj", function()
	-- `/` - Start a search forwards from the current cursor position.
	-- `^` - Match the beginning of a line.
	-- `##` - Match 2 ## symbols
	-- `\\+` - Match one or more occurrences of prev element (#)
	-- `\\s` - Match exactly one whitespace character following the hashes
	-- `.*` - Match any characters (except newline) following the space
	-- `$` - Match extends to end of line
	vim.cmd("silent! /^##\\+\\s.*$")
	-- Clear the search highlight
	vim.cmd("nohlsearch")
end, { desc = "Go to next markdown header" })
