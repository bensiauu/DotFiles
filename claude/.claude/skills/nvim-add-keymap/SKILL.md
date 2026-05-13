---
name: nvim-add-keymap
description: Use this skill when the user wants to "add a neovim keymap", "bind <key> in nvim", or "make <leader>X do Y" in their LazyVim config. Appends to `lua/config/keymaps.lua` or extends a plugin spec's `keys = { … }` table. Delegate to the neovim-config-engineer agent for substantive nvim work.
version: 0.1.0
---

# Add a Neovim keymap

## When to use
The user wants to bind a key in Neovim — typical phrasing: "bind <leader>gd to LSP definition", "map jj to ESC". If they're talking about the shell, use `zsh-add-keybinding`.

## Where the keymap lives
Decision:
- **Plugin-specific binding** (the key invokes a command from a specific plugin) → add to that plugin's `keys = { … }` table in `lua/plugins/<topic>.lua`. This triggers lazy-load on first use.
- **Global / vim-builtin / cross-plugin binding** → add to `lua/config/keymaps.lua`.

## Existing bindings to respect
From `lua/config/keymaps.lua`:
- `jk` → ESC in insert mode.
- `<C-h/j/k/l>` → window navigation.
- `<leader>wh/wj/wk/wl` → window navigation (alt).
- `<leader>bp/bn`, `<leader>[b/]b` → buffer prev/next.
- `<leader>fs` → write buffer.
- `gk/gj` → markdown header navigation.
- `<leader>ft` → fish float terminal.

Don't reassign any of those without asking.

## Forms

### Global keymap (`lua/config/keymaps.lua`)
```lua
vim.keymap.set("n", "<leader>xx", function()
  -- some action
end, { desc = "Do thing" })

vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
```

### Plugin-spec keys
```lua
return {
  {
    "owner/repo",
    keys = {
      { "<leader>xx", "<cmd>SomeCmd<cr>", desc = "Description", mode = "n" },
      { "<leader>xy", function() require("plugin").action() end, desc = "Action" },
    },
  },
}
```

## Steps
1. Confirm with the user: mode (`n`/`i`/`v`/`x`/`t`), lhs (the chord), rhs (command, function, or string), and a desc.
2. Decide: is this tied to a specific plugin? If yes → plugin spec's `keys`. Else → `lua/config/keymaps.lua`.
3. Always include `desc = "..."` — LazyVim's which-key surfaces these.
4. Use `vim.keymap.set` (modern API). Don't use `vim.api.nvim_set_keymap` for new keymaps even though existing lines use it.
5. For chord prefixes that conflict with a LazyVim default, surface the conflict first.

## House style
- `vim.keymap.set(modes, lhs, rhs, { desc = "..." })`.
- Always a desc.
- `noremap` and `silent` default to true in `vim.keymap.set` — don't repeat them unless overriding.

## Reporting
List the file touched, mode(s), lhs, rhs, and desc. No reload needed — LazyVim picks up keymap changes on next file open or via `:source %`.
