-- Set conceal level to 2 when markdown file
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	command = "setlocal conceallevel=2",
})
