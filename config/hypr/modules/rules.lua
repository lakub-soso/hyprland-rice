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

-- Steam games (Proton and Steam-launched: class steam_app_<appid>) open
-- fullscreen. Many of them do "borderless fullscreen" by sizing themselves to
-- the screen or sending a maximize request (suppressed above), never a real
-- fullscreen request, so in a tiling WM they'd end up as a tile.
-- Only tiled windows: launchers, splash screens and dialogs float, and
-- they're left alone. idle_inhibit: no screen lock/sleep mid-game.
hl.window_rule({
    name  = "steam-games-fullscreen",
    match = { class = "^(steam_app_\\d+)$", float = false },

    fullscreen   = true,
    idle_inhibit = "fullscreen",
})

-- Switching away (Alt+Tab to Steam, launching an app) un-fullscreens the game;
-- going back to it makes it fullscreen again. Super+Shift+F still un-fullscreens
-- it for as long as it stays focused.
hl.on("window.active", function(w)
    if w and not w.floating and (w.fullscreen or 0) == 0
        and tostring(w.class or ""):match("^steam_app_%d+$") then
        hl.dispatch(hl.dsp.window.fullscreen())
    end
end)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
