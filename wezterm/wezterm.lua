local wezterm = require("wezterm")
local mux = wezterm.mux

return {
	-- Font configuration
	font = wezterm.font("SF Mono", { weight = "Regular", italic = false }),
	font_size = 16.0,

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
	},

	-- Key bindings
	leader = {
		key = " ",
		mods = "CTRL",
		timeout_milliseconds = 1000,
	},

	keys = {
		{ key = "t", mods = "LEADER", action = wezterm.action({ SpawnTab = "DefaultDomain" }) },
		{
			key = "w",
			mods = "LEADER",
			action = wezterm.action.CloseCurrentPane({ confirm = false }),
		},
		{ key = "LeftArrow", mods = "LEADER", action = wezterm.action({ ActivateTabRelative = -1 }) },
		{ key = "RightArrow", mods = "LEADER", action = wezterm.action({ ActivateTabRelative = 1 }) },
		{
			key = "e",
			mods = "LEADER",
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
		{
			key = "v",
			mods = "LEADER",
			action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "V",
			mods = "LEADER",
			action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "S",
			mods = "LEADER",
			action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "s",
			mods = "LEADER",
			action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
		},

		-- Move between panes with Ctrl+Shift+h/j/k/l
		{
			key = "h",
			mods = "LEADER",
			action = wezterm.action.ActivatePaneDirection("Left"),
		},
		{
			key = "j",
			mods = "LEADER",
			action = wezterm.action.ActivatePaneDirection("Down"),
		},
		{
			key = "k",
			mods = "LEADER",
			action = wezterm.action.ActivatePaneDirection("Up"),
		},
		{
			key = "l",
			mods = "LEADER",
			action = wezterm.action.ActivatePaneDirection("Right"),
		},
		{
			key = "w",
			mods = "LEADER",
			action = wezterm.action.CloseCurrentPane({ confirm = false }),
		},
	},

	-- Appearance settings
	--
	window_decorations = "RESIZE",

	-- Misc settings
	enable_scroll_bar = true,
	default_prog = { "/opt/homebrew/bin/fish", "-l" },
}
