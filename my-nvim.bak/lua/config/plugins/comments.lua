-- Easily comment visual regions/lines
return {
	"numToStr/Comment.nvim",
	opts = {},
	config = function()
		local opts = { noremap = true, silent = true }
		vim.keymap.set("n", "gc", require("Comment.api").toggle.linewise.current, opts)
		vim.keymap.set("v", "gc", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", opts)
	end,
}
