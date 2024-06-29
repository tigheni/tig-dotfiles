local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.cursor_blink_rate = 500
config.font = wezterm.font("JetBrains Mono", { weight = "Medium" })
config.font_size = 11
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.hide_mouse_cursor_when_typing = false
config.harfbuzz_features = { "calt=0", "clig=1", "liga=1" }
config.hide_tab_bar_if_only_one_tab = true
config.warn_about_missing_glyphs = false
config.term = "xterm-256color"
config.color_scheme = "Whimsy"
config.window_background_opacity = 0.85
return config
