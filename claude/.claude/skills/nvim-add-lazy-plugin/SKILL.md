---
name: nvim-add-lazy-plugin
description: Use this skill when the user wants to "add a neovim plugin", "install a lazyvim plugin", or "wire up <plugin> in nvim". Creates or extends a file under `nvim/.config/nvim/lua/plugins/` with a properly-shaped lazy.nvim spec table. Delegate substantive config to the neovim-config-engineer agent.
version: 0.1.0
---

# Add a lazy.nvim plugin

## When to use
The user wants to install a new Neovim plugin via lazy.nvim — typical phrasing: "add telescope extension X", "install neogit", "wire up the Y LSP". If they're customising an existing plugin or doing broader nvim work, hand off to `neovim-config-engineer` directly.

## Where the plugin lives
Plugin specs live in `nvim/.config/nvim/lua/plugins/<topic>.lua`. Existing files include `colorscheme.lua`, `dashboard.lua`, `neogit.lua`, `obsidian.lua`, `flutter.lua`.

Rules:
- If a topic file already covers the plugin's domain (e.g. adding a git plugin → `neogit.lua` or create `git.lua`), extend that file.
- Otherwise create a new `<topic>.lua` with a single-purpose name.
- LazyVim auto-imports anything under `lua/plugins/` via `{ import = "plugins" }` — no manual registration.

## Spec shape (the house style)
```lua
return {
  {
    "owner/repo",
    event = "VeryLazy",                       -- or cmd / ft / keys
    dependencies = { "other/plugin" },        -- optional
    opts = {
      some_option = true,
    },
    keys = {
      { "<leader>xx", "<cmd>SomeCmd<cr>", desc = "Do thing", mode = "n" },
    },
    config = function(_, opts)                -- only if opts isn't enough
      require("owner.repo").setup(opts)
    end,
  },
}
```

## Lazy-load triggers — pick the laziest that still works
| Trigger | When to use |
|---|---|
| `event = "VeryLazy"` | UI tweaks, statuslines, plugins not tied to a file |
| `event = { "BufReadPre", "BufNewFile" }` | Plugins that should load when a real file opens |
| `ft = { "lua", "go" }` | Filetype-specific (LSP servers, language tools) |
| `cmd = { "FooCmd" }` | Plugin only used via a command |
| `keys = { ... }` | Plugin only triggered by user keymaps (defining `keys` triggers load on first use) |

## Steps
1. Confirm with the user (or infer): plugin `owner/repo`, what the plugin does, what triggers it, any keymaps the user wants for it.
2. Decide on the topic file: extend an existing `lua/plugins/*.lua` if there's a fit, else create a new one with a clear name.
3. Write the spec table following the shape above. Always include a `desc` on every key.
4. If the plugin is an LSP server, prefer wiring it through `nvim-lspconfig`'s servers list rather than as a standalone plugin.
5. Remind the user to run `:Lazy sync` inside Neovim to install.

## House style (matches neovim-config-engineer's hard rules)
- Use `opts = {}` over `config = function() … end` whenever possible.
- Always include `desc` on keys.
- Don't override `jk → ESC` or `Ctrl-h/j/k/l` window nav.
- 2-space indent, double quotes, trailing commas.

## Reporting
List the file touched (created or extended), the lazy-load trigger chosen, any new keymaps, and the `:Lazy sync` reminder.
