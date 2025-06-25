return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                transparent_background = true,
                term_colors = true,
            })
        end,
    },
    {
        "navarasu/onedark.nvim",
        name = "onedark",
        config = function()
            require("onedark").setup({})
        end,
    },
    {
        "miikanissi/modus-themes.nvim",
        name = "modus",
        priority = 1000,
        config = function()
            require("modus-themes").setup({

                style = "modus_operandi",
                variant = "tinted",
                dim_inactive = true,
            })
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin-frappe",
        },
    },
}
