-- Seamless nvim <-> zellij navigation.
--
-- Pairs with the `vim-zellij-navigator` zellij plugin (see ~/.config/zellij/config.kdl):
--   • In a SHELL pane, Ctrl+h/j/k/l is handled entirely by zellij.
--   • In an NVIM pane, zellij forwards Ctrl+h/j/k/l into nvim; smart-splits moves
--     between nvim splits and, at the outermost edge, crosses into the adjacent
--     zellij pane via zellij's CLI (auto-detected through the $ZELLIJ env var).
--
-- Note: Alt+h/j/k/l are intentionally NOT mapped here — zellij owns those.
return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Focus split/pane left" },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Focus split/pane down" },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Focus split/pane up" },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Focus split/pane right" },
    },
    opts = {
      -- when there's no nvim split AND no multiplexer pane in that direction:
      at_edge = "stop",
    },
  },
}
