local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }
keymap("n", "<Space>", "", { noremap = true, silent = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

keymap("n", "<leader>ff", "<cmd>lua require('vscode').action('workbench.action.quickOpen')<CR>", opts)
keymap("n", "<leader>p", "<cmd>lua require('vscode').action('workbench.action.showCommands')<CR>", opts)
-- project manager keymaps
keymap("n", "<leader>pa", "<cmd>lua require('vscode').action('projectManager.saveProject')<CR>", opts)
keymap("n", "<leader>pl", "<cmd>lua require('vscode').action('projectManager.listProjectsNewWindow')<CR>", opts)
keymap("n", "<leader>pe", "<cmd>lua require('vscode').action('projectManager.editProjects')<CR>", opts)

-- pane navigation
keymap("n", "<leader>wl", "<cmd>lua require('vscode').action('workbench.action.focusRightGroup')<CR>", opts)
keymap("n", "<leader>wh", "<cmd>lua require('vscode').action('workbench.action.focusLeftGroup')<CR>", opts)
keymap("n", "<leader>wk", "<cmd>lua require('vscode').action('workbench.action.focusAboveGroup')<CR>", opts)
keymap("n", "<leader>wj", "<cmd>lua require('vscode').action('workbench.action.focusBelowGroup')<CR>", opts)

-- Split panes
keymap("n", "<leader>ws", "<cmd>lua require('vscode').action('workbench.action.splitEditorDown')<CR>", opts)
keymap("n", "<leader>wv", "<cmd>lua require('vscode').action('workbench.action.splitEditor')<CR>", opts)

-- Close current pane
keymap("n", "<leader>wc", "<cmd>lua require('vscode').action('workbench.action.closeGroup')<CR>", opts)

-- Navigate between tabs
keymap("n", "<leader>bp", "<cmd>lua require('vscode').action('workbench.action.previousEditor')<CR>", opts) -- Previous tab
keymap("n", "<leader>bn", "<cmd>lua require('vscode').action('workbench.action.nextEditor')<CR>", opts) -- Next tab
keymap("n", "<leader>bk", "<cmd>lua require('vscode').action('workbench.action.closeActiveEditor')<CR>", opts) -- Close current tab
keymap("n", "<leader>bl", "<cmd>lua require('vscode').action('workbench.action.showAllEditors')<CR>", opts) -- Show tab list
