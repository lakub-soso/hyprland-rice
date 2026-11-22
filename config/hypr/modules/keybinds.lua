---------------------
---- KEYBINDINGS ----
---------------------

-- Every bind goes through cs.bind(keys, action, description[, opts]) so it
-- shows up in the cheatsheet (SUPER + /). See modules/cheatsheet.lua.
-- Bind reference: https://wiki.hypr.land/configuring/core/binds/

local programs = require("modules.programs")
local cs       = require("modules.cheatsheet")
local mainMod  = programs.mainMod
local function mod(keys) return mainMod .. " + " .. keys end

cs.section("General")
cs.bind(mod("slash"), hl.dsp.exec_cmd(cs.command), "Toggle this cheatsheet")
cs.bind(mod("L"),     hl.dsp.exec_cmd("pidof hyprlock || hyprlock"), "Lock screen") -- config/hypr/hyprlock.conf
-- Exit is deliberately awkward (moved off SUPER + M, next to the mic mute key);
-- logging out normally goes through the power menu (SUPER + Esc).
cs.bind(mod("CTRL + SHIFT + M"), hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), "Exit Hyprland")
cs.bind(mod("SHIFT + M"), hl.dsp.exec_cmd("~/.config/hypr/scripts/mic.sh toggle"), "Mute / unmute microphone")
cs.bind(mod("Escape"), hl.dsp.exec_cmd(programs.power), "Power menu")
-- keyboard layout switching is XKB (input.lua), not a Hyprland bind: list it only
cs.note("ALT + SHIFT", "Switch layout: EN · UA · RU")

cs.section("Apps")
cs.bind(mod("space"), hl.dsp.exec_cmd(programs.menu),        "Launcher: apps · calc · files · windows")
cs.bind(mod("V"),     hl.dsp.exec_cmd(programs.clipboard),   "Clipboard history")
-- rofi-emoji: Enter types the emoji into the focused window (wtype) + copies it
-- no icon column (emoji have no icons → empty 24px slot) and no one-tab mode bar
cs.bind(mod("period"), hl.dsp.exec_cmd("pkill -x rofi || rofi -modi emoji -show emoji -no-show-icons -theme-str 'mainbox { children: [ inputbar, message, listview ]; }'"), "Emoji picker")
cs.bind(mod("SHIFT + C"), hl.dsp.exec_cmd("~/.config/hypr/scripts/colorpicker.sh"), "Color picker (copies hex)")
cs.bind(mod("T"),     hl.dsp.exec_cmd(programs.terminal),    "Terminal")
cs.bind(mod("E"),     hl.dsp.exec_cmd(programs.fileManager), "File manager")

cs.section("Screenshots")
-- Saved to ~/Pictures/Screenshots + copied; click the notification to annotate
cs.bind(mod("SHIFT + S"), hl.dsp.exec_cmd("~/.config/hypr/scripts/snip.sh"), "Snip region / click a window")

cs.section("Windows")
-- close = polite close request (app can save); kill = SIGKILL, like SuperF4
local closeWindowBind = cs.bind(mod("Q"), hl.dsp.window.close(), "Close window")
-- closeWindowBind:set_enabled(false)
cs.bind(mod("SHIFT + Q"), hl.dsp.window.kill(), "Force-kill window (SIGKILL)")
cs.bind(mod("F"), hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
cs.bind(mod("P"), hl.dsp.window.pseudo(),                     "Pseudo-tile")
cs.bind(mod("J"), hl.dsp.layout("togglesplit"),               "Toggle split direction") -- dwindle only

-- Move focus with mainMod + arrow keys
cs.bind(mod("left"),  hl.dsp.focus({ direction = "left" }),  "Focus left")
cs.bind(mod("right"), hl.dsp.focus({ direction = "right" }), "Focus right")
cs.bind(mod("up"),    hl.dsp.focus({ direction = "up" }),    "Focus up")
cs.bind(mod("down"),  hl.dsp.focus({ direction = "down" }),  "Focus down")

-- Move the focused window within the workspace (swaps with the neighbour in
-- that direction; at a monitor edge it moves to the next monitor)
cs.bind(mod("SHIFT + left"),  hl.dsp.window.move({ direction = "left" }),  "Move window left")
cs.bind(mod("SHIFT + right"), hl.dsp.window.move({ direction = "right" }), "Move window right")
cs.bind(mod("SHIFT + up"),    hl.dsp.window.move({ direction = "up" }),    "Move window up")
cs.bind(mod("SHIFT + down"),  hl.dsp.window.move({ direction = "down" }),  "Move window down")

-- Move/resize windows with mainMod + LMB/RMB and dragging
cs.bind(mod("mouse:272"), hl.dsp.window.drag(),   "Move window",   { mouse = true })
cs.bind(mod("mouse:273"), hl.dsp.window.resize(), "Resize window", { mouse = true })

cs.section("Workspaces")
-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
cs.note(mod("1-0"),         "Go to workspace 1-10")
cs.note(mod("SHIFT + 1-0"), "Move window to workspace 1-10")
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    cs.bind(mod(key),              hl.dsp.focus({ workspace = i }),       "Go to workspace " .. i,         { hidden = true })
    cs.bind(mod("SHIFT + " .. key), hl.dsp.window.move({ workspace = i }), "Move window to workspace " .. i, { hidden = true })
end

-- Special workspace (scratchpad)
cs.bind(mod("S"),         hl.dsp.workspace.toggle_special("magic"),          "Toggle scratchpad")
cs.bind(mod("ALT + S"),   hl.dsp.window.move({ workspace = "special:magic" }), "Move window to scratchpad")

-- Scroll through existing workspaces with mainMod + scroll
cs.bind(mod("mouse_down"), hl.dsp.focus({ workspace = "e+1" }), "Next workspace")
cs.bind(mod("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }), "Previous workspace")

-- Beyond 1-10: workspaces can have any number. "r±1" = next/previous by
-- number (creates it if needed, e.g. 11), "empty" = lowest-numbered free one.
cs.bind(mod("CTRL + right"),         hl.dsp.focus({ workspace = "r+1" }),          "Next workspace (creates 11, 12…)")
cs.bind(mod("CTRL + left"),          hl.dsp.focus({ workspace = "r-1" }),          "Previous workspace")
cs.bind(mod("CTRL + SHIFT + right"), hl.dsp.window.move({ workspace = "r+1" }),    "Move window to next workspace")
cs.bind(mod("CTRL + SHIFT + left"),  hl.dsp.window.move({ workspace = "r-1" }),    "Move window to previous workspace")
cs.bind(mod("N"),                    hl.dsp.focus({ workspace = "empty" }),        "New empty workspace")
cs.bind(mod("SHIFT + N"),            hl.dsp.window.move({ workspace = "empty" }),  "Move window to new empty workspace")

cs.section("Media")
-- Multimedia keys for volume and LCD brightness
cs.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up",       { locked = true, repeating = true })
cs.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      "Volume down",     { locked = true, repeating = true })
cs.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     "Mute",            { locked = true, repeating = true })
cs.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("~/.config/hypr/scripts/mic.sh toggle"),         "Mute mic",        { locked = true })
cs.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  "Brightness up",   { locked = true, repeating = true, hidden = true })
cs.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  "Brightness down", { locked = true, repeating = true, hidden = true })

-- Requires playerctl
cs.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       "Next track",     { locked = true })
cs.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Play / pause",   { locked = true, hidden = true })
cs.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), "Play / pause",   { locked = true })
cs.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   "Previous track", { locked = true })

cs.write()
