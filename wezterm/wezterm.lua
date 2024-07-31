local wezterm = require("wezterm")
local mux = wezterm.mux

return {
	-- Font configuration
	font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Regular", italic = false }),
	font_size = 12.0,

	-- Maximize screen on start
	wezterm.on("gui-startup", function()
		local tab, pane, window = mux.spawn_window({})
		window:gui_window():maximize()
	end),

	-- Color scheme
	color_scheme = "Kanagawa (Gogh)",
	colors = {
		foreground = "#DCD7BA",
		background = "#1F1F28",
		cursor_bg = "#C8C093",
		cursor_fg = "#C8C093",
		cursor_border = "#C8C093",
		selection_fg = "#C8C093",
		selection_bg = "#2D4F67",
		ansi = {
			"#16161D",
			"#C34043",
			"#76946A",
			"#C0A36E",
			"#7E9CD8",
			"#957FB8",
			"#6A9589",
			"#C8C093",
		},
		brights = {
			"#727169",
			"#E82424",
			"#98BB6C",
			"#E6C384",
			"#7FB4CA",
			"#938AA9",
			"#7AA89F",
			"#DCD7BA",
		},
	},
	-- Tab bar configuration
	hide_tab_bar_if_only_one_tab = true,
	tab_bar_at_bottom = true,
	use_fancy_tab_bar = true,

	-- Window padding
	window_padding = {
		left = 10,
		right = 10,
		top = 10,
		bottom = 10,
	},

	-- Key bindings
	keys = {
		{ key = "t", mods = "CTRL|SHIFT", action = wezterm.action({ SpawnTab = "DefaultDomain" }) },
		{ key = "w", mods = "CTRL|SHIFT", action = wezterm.action({ CloseCurrentTab = { confirm = true } }) },
		{ key = "LeftArrow", mods = "CTRL|SHIFT", action = wezterm.action({ ActivateTabRelative = -1 }) },
		{ key = "RightArrow", mods = "CTRL|SHIFT", action = wezterm.action({ ActivateTabRelative = 1 }) },
		{
			key = "E",
			mods = "CTRL|SHIFT",
			action = wezterm.action.PromptInputLine({
				description = "Enter new name for tab",
				action = wezterm.action_callback(function(window, pane, line)
					-- line will be `nil` if they hit escape without entering anything
					-- An empty string if they just hit enter
					-- Or the actual line of text they wrote
					if line then
						window:active_tab():set_title(line)
					end
				end),
			}),
		},
	},
	-- Appearance settings
	--
	window_decorations = "RESIZE",
	window_background_opacity = 0.9,

	-- Misc settings
	enable_scroll_bar = true,
	default_prog = { "/opt/homebrew/bin/fish", "-l" },
}
