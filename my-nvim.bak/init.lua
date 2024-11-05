if vim.g.vscode then
	-- VSCode extension
	require("config.core.keymaps")
	require("config.vscode.keymaps")
else
	-- ordinary Neovim
	require("config.core.keymaps")
	require("config.core.options")
	require("config.core.autocmds")
	require("config.lazy")
end
