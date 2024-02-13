local wezterm = require("wezterm")
local config = wezterm.config_builder()
local mux = wezterm.mux

wezterm.on("gui-startup", function()
	local _, _, window = mux.spawn_window({})
	window:gui_window():maximize()
	window:gui_window():toggle_fullscreen()
end)

config.cursor_blink_rate = 0
config.font = wezterm.font("JetBrains Mono", { weight = "Medium" })
config.font_size = 11
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.harfbuzz_features = { "calt=0", "clig=1", "liga=1" }
config.hide_tab_bar_if_only_one_tab = true
config.warn_about_missing_glyphs = false

return config
