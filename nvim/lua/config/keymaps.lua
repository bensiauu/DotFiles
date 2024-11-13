-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
vim.api.nvim_set_keymap("n", "<leader>fs", ":w<CR>", { noremap = true, silent = true, desc = "Write buffer" })
vim.api.nvim_set_keymap("n", "<C-h>", "<C-w>h", { noremap = true, silent = true, desc = "Switch to Buffer Left" })
vim.api.nvim_set_keymap("n", "<C-j>", "<C-w>j", { noremap = true, silent = true, desc = "Switch to Buffer below" })
vim.api.nvim_set_keymap("n", "<C-k>", "<C-w>k", { noremap = true, silent = true, desc = "Switch to buffer above" })
vim.api.nvim_set_keymap("n", "<C-l>", "<C-w>l", { noremap = true, silent = true, desc = "Switch to buffer right" })

vim.api.nvim_set_keymap("n", "<leader>wh", "<C-w>h", { noremap = true, silent = true, desc = "Switch to Buffer Left" })
vim.api.nvim_set_keymap("n", "<leader>wj", "<C-w>j", { noremap = true, silent = true, desc = "Switch to Buffer below" })
vim.api.nvim_set_keymap("n", "<leader>wk", "<C-w>k", { noremap = true, silent = true, desc = "Switch to buffer above" })
vim.api.nvim_set_keymap("n", "<leader>wl", "<C-w>l", { noremap = true, silent = true, desc = "Switch to buffer right" })
-- buffers
vim.api.nvim_set_keymap("n", "<leader>bp", ":bprev<CR>", { noremap = true, silent = true, desc = "Buffer Previous" })
vim.api.nvim_set_keymap("n", "<leader>bn", ":bnext<CR>", { noremap = true, silent = true, desc = "Buffer Next" })
vim.api.nvim_set_keymap("n", "<leader>bk", ":bdelete<CR>", { noremap = true, silent = true, desc = "Buffer Kill" })

-- markdown jump heading
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

-- Open floating terminal in Fish shell
vim.api.nvim_set_keymap(
  "n",
  "<leader>ft",
  ":lua require('lazy.util').float_term({ 'fish' })<CR>",
  { noremap = true, silent = true }
)
