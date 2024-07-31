-- Create group to assign commands
-- "clear = true" must be set to prevent loading an
-- auto-command repeatedly every time a file is resourced
local autocmd_group = vim.api.nvim_create_augroup("CustomAutoCommands", { clear = true })

-- Auto-format Python files after saving
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	pattern = { "*.py" },
	desc = "Auto-format Python files after saving",
	callback = function()
		local fileName = vim.api.nvim_buf_get_name(0)
		vim.cmd(":silent !ruff format " .. fileName)
		vim.cmd(":silent !isort --profile black --float-to-top -q " .. fileName)
		vim.cmd(":silent !docformatter --in-place --black " .. fileName)
	end,
	group = autocmd_group,
})

-- Define the Prettier command
vim.cmd([[
  command! -nargs=0 Prettier :%!prettier --stdin-filepath % --single-quote --trailing-comma all
]])

-- Run Prettier on save for TypeScript and JavaScript files
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
	desc = "Auto-format TypeScript and JavaScript files before saving",
	callback = function()
		vim.cmd(":Prettier")
	end,
	group = autocmd_group,
})

-- Lua files formatter
vim.cmd([[
    command! -nargs=0 Stylua :!stylua %
]])

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	pattern = "*.lua",
	callback = function()
		vim.cmd(":silent Stylua")
	end,
	group = autocmd_group,
})

vim.api.nvim_create_augroup("Transparency", {})
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
		vim.cmd("highlight NonText guibg=NONE ctermbg=NONE")
	end,
	group = "Transparency",
})
