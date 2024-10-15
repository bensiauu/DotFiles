return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,
	ft = "markdown",
	-- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
	-- event = {
	--   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
	--   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
	--   -- refer to `:h file-pattern` for more examples
	--   "BufReadPre path/to/my-vault/*.md",
	--   "BufNewFile path/to/my-vault/*.md",
	-- },
	dependencies = {
		-- Required.
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "~/Documents/Ben_Ideaverse/",
			},
		},
	},
	config = function()
		-- Set up obsidian.nvim
		require("obsidian").setup({
			dir = "~/Documents/Ben_Ideaverse/", -- Your Obsidian vault path
			completion = {
				nvim_cmp = true, -- Enable completion using nvim-cmp
			},
			---@return table
			note_frontmatter_func = function(note)
				-- Start with the note's metadata to preserve all frontmatter fields.
				local out = {}

				if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
					-- Copy all manually added frontmatter fields.
					for k, v in pairs(note.metadata) do
						out[k] = v
					end
				end

				-- Add the title of the note as an alias if available.
				if note.title then
					note:add_alias(note.title)
				end

				-- Now, overwrite or add the predefined fields (id, aliases, and tags).
				out.id = note.id
				out.aliases = note.aliases
				out.tags = note.tags

				return out
			end,
		})

		-- Set keymap for opening the current file in Obsidian
		vim.api.nvim_set_keymap(
			"n",
			"<leader>oo",
			":ObsidianOpen<CR>",
			{ noremap = true, silent = true, desc = "Open current file in Obsidian" }
		)
	end,
}
