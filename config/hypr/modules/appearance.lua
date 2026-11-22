-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/configuring/core/config-options/
local c = require("modules.colors")

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 12,   -- screen edge ↔ windows

        border_size = 2,

        col = {
            active_border   = { colors = { c.rgba("accent", "ee"), c.rgba("accent2", "ee") }, angle = 45 },
            inactive_border = c.rgba("surface1", "aa"),
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 8,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = c.rgba("crust", "ee"),
        },

        -- Blur shows through anything translucent: kitty, dolphin, rofi, dunst,
        -- waybar (see modules/rules.lua for the layer/window rules).
        blur = {
            enabled   = true,
            size      = 8,
            passes    = 3,      -- smoother "frosted glass" than the default 1
            noise     = 0.02,   -- a little grain, avoids banding on dark colours
            vibrancy  = 0.1696,
        },
    },
})
