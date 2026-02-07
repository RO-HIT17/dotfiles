local wezterm = require 'wezterm'

wezterm.on("update-right-status", function(window)
  local battery = ""
  for _, b in ipairs(wezterm.battery_info()) do
    battery = string.format("🔋%.0f%%", b.state_of_charge * 100)
  end

  window:set_right_status(
    wezterm.format({
      { Foreground = { Color = "#7aa2f7" } },
      { Text = " " .. battery },
      { Text = " · " },
      { Text = wezterm.strftime("%H:%M") .. "  " },
    })
  )
end)

wezterm.on("format-window-title", function()
  return "WezTerm"
end)

wezterm.on("format-tab-title", function(tab)
  local pane = tab.active_pane
  local title = pane.title

  title = title:gsub("wslhost%.exe", "")
  title = title:gsub("WSL:.*", "")
  title = title:gsub(".*/", "")

  if title == "" then
    title = "zsh"
  end

  return {
    { Text = "  " .. title .. "  " },
  }
end)



return {

  default_domain = "WSL:Ubuntu",
  default_cwd = "/home/rohit/",

  color_scheme = "Tokyo Night",

  font = wezterm.font({
  family = "MesloLGS Nerd Font",
  weight = "Bold",
	}),
  font_size = 11,

  window_background_opacity = 1,
  use_fancy_tab_bar = false,
  tab_bar_at_bottom = false,	
  tab_max_width = 20,

  window_padding = {
    left = 10,
    right = 10,
    top = 8,
    bottom = 8,
  },
  mouse_bindings = {
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = wezterm.action.PasteFrom "Clipboard",
  },
  
}

}
