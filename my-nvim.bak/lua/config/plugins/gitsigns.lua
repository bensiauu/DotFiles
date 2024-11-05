return {
	"lewis6991/gitsigns.nvim",
	config = function()
		require("gitsigns").setup({
			signs = {
				add = { text = "▎" }, -- Sign for added lines
				change = { text = "▎" }, -- Sign for changed lines
				delete = { text = "_" }, -- Sign for deleted lines
				topdelete = { text = "‾" }, -- Sign for deleted lines above the current line
				changedelete = { text = "~" }, -- Sign for lines changed then deleted
				untracked = { text = "┆" }, -- Sign for untracked lines
			},
			numhl = false, -- Disable number highlighting
			linehl = false, -- Disable line highlighting
			word_diff = false, -- Only highlight the part of a line that changed

			-- Keymaps for common actions
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				-- Define a function to easily map keys with options
				local function map(mode, lhs, rhs, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, lhs, rhs, opts)
				end

				-- Navigation
				map("n", "]c", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Next git hunk" })

				map("n", "[c", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Previous git hunk" })

				-- Actions
				map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
				map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
				map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage entire buffer" })
				map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo last stage" })
				map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset entire buffer" })
				map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
				map("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, { desc = "Blame line" })
				map("n", "<leader>hd", gs.diffthis, { desc = "View diff" })
				map("n", "<leader>hD", function()
					gs.diffthis("~")
				end, { desc = "View diff against base" })

				-- Toggle options
				map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle current line blame" })
				map("n", "<leader>td", gs.toggle_deleted, { desc = "Toggle deleted lines" })
			end,
		})
	end,
}
