--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/configuring/core/rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

--------------------------------
---- TRANSPARENCY AND BLUR ----
--------------------------------
-- Blur settings: decoration.blur in modules/appearance.lua.

-- Layer surfaces (launcher, notifications, bar) don't get blur by default.
-- ignore_alpha: don't blur fully/mostly transparent pixels, i.e. the area
-- outside their rounded corners.
for _, ns in ipairs({ "rofi", "notifications", "waybar", "logout_dialog" }) do  -- logout_dialog = wlogout
    hl.layer_rule({
        name         = "blur-" .. ns,
        match        = { namespace = "^" .. ns .. "$" },
        blur         = true,
        ignore_alpha = 0.3,
    })
end

-- Kitty has its own background_opacity (text stays opaque): config/kitty.
-- Dolphin has no transparency setting, so make the whole window translucent
-- (active, inactive).
hl.window_rule({
    name    = "translucent-dolphin",
    match   = { class = "^(org\\.kde\\.dolphin)$" },
    opacity = "0.92 0.85",
})

-- JetBrains Toolbox places its popup next to the tray icon itself, but under
-- XWayland it gets the coordinates wrong and lands off-screen (e.g. x=-440).
-- It also moves itself after map, so a `move` rule alone gets overridden:
-- re-pin it to the top-right corner (below waybar) whenever it opens or is
-- focused from the tray.
hl.window_rule({
    name  = "jetbrains-toolbox-popup",
    match = { class = "^(jetbrains-toolbox)$" },

    float = true,
    move  = "monitor_w-window_w-10 40",
})

local toolboxMove = "hl.dsp.window.move({ x = 2120, y = 40, window = 'class:^(jetbrains-toolbox)$' })"
local function pinToolbox(w)
    if w and w.class == "jetbrains-toolbox" then
        -- Delayed, since Toolbox repositions itself right after these events.
        hl.dispatch(hl.dsp.exec_cmd('sleep 0.3; hyprctl dispatch "' .. toolboxMove .. '"'))
    end
end
hl.on("window.open",   pinToolbox)
hl.on("window.active", pinToolbox)

-- Games: Steam/Proton (class steam_app_<appid>) and gamescope.
-- Fullscreen is left to the game (set Display mode → Fullscreen in-game):
-- Proton asks for real fullscreen when the window covers a monitor, which
-- works once XWayland's primary output is the main monitor
-- (scripts/xwayland-primary.sh). Same approach as end-4 / JaKooLit's dots.
--   immediate: tearing allowed (general.allow_tearing) → lowest input lag
--   no_blur:   no blur pass behind the game
hl.window_rule({
    name  = "games",
    match = { class = "^(steam_app_\\d+|gamescope)$" },

    immediate = true,
    no_blur   = true,
})

-- No screen lock/sleep while anything is fullscreen (games, videos)
hl.window_rule({
    name  = "fullscreen-idle-inhibit",
    match = { fullscreen = true },

    idle_inhibit = "fullscreen",
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
