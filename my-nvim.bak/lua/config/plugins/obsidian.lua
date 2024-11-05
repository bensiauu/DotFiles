return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,
	ft = "markdown",
	--event = {
	-- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
	-- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
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
				path = "~/Documents/Ben_Ideaverse",
			},
		},
		templates = {
			folder = "Templates",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M",
			-- A map for custom variables, the key should be the variable and the value a function
			substitutions = {},
		},
		daily_notes = {
			-- Optional, if you keep daily notes in a separate directory.
			folder = "Journal/2024",
			-- Optional, if you want to change the date format for the ID of daily notes.
			date_format = "%Y-%m-%d",
			-- Optional, if you want to change the date format of the default alias of daily notes.
			alias_format = "%B %-d, %Y",
			-- Optional, default tags to add to each new daily note created.
			default_tags = { "daily-notes" },
			-- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
			template = "Daily Note Template.md",
		},
		mappings = {
			-- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
			["gf"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
			},
			-- Toggle check-boxes.
			["<leader>ch"] = {
				action = function()
					return require("obsidian").util.toggle_checkbox()
				end,
				opts = { buffer = true },
			},
			-- Smart action depending on context, either follow link or toggle checkbox.
			["<cr>"] = {
				action = function()
					return require("obsidian").util.smart_action()
				end,
				opts = { buffer = true, expr = true },
			},
			["<leader>o/"] = { action = ":ObsidianSearch<CR>", desc = "Search notes" },
			["<leader>op"] = { action = ":ObsidianQuickSwitch<CR>", desc = "Quick switch" },
			["<leader>ob"] = { action = ":ObsidianBacklinks<CR>", desc = "Show backlinks" },
			["<leader>on"] = { action = ":ObsidianNew<CR>", desc = "Create new note" },
			["<leader>ot"] = { action = ":ObsidianToday<CR>", desc = "Go to Today's daily note" },
		},
	},
}
