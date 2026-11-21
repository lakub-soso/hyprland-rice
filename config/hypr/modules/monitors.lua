------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
-- Monitors are matched by description prefix (make + model, serial omitted on
-- purpose — see `hyprctl monitors all`), not port, so swapping cables doesn't
-- break the layout.
--
-- Layout:  [ 1: Philips 1440p@144 ][ 2: Samsung 1080p@60, portrait ]
--          Tops of both screens aligned at y = 0.
-- The Philips is the main monitor: it gets workspace 1 and the only waybar
-- (see config/waybar/config.jsonc — that one matches by port, HDMI-A-3,
-- because waybar can't match a description without the serial).

local PHILIPS = "desc:Philips Consumer Electronics Company 27M2N5500"
local SAMSUNG = "desc:Samsung Electric Company F27G3xTF"

-- 1: Philips 27M2N5500, landscape, left
hl.monitor({
    output   = PHILIPS,
    mode     = "2560x1440@144",
    position = "0x0",
    scale    = 1,
})

-- 2: Samsung F27G3xTF, portrait, right of the Philips
hl.monitor({
    output    = SAMSUNG,
    mode      = "1920x1080@60",
    position  = "2560x0",
    scale     = 1,
    transform = 1, -- 90° clockwise; use 3 if the screen is rotated the other way
})

-- Main monitor: workspace 1 always opens on the Philips
hl.workspace_rule({ workspace = "1", monitor = PHILIPS, default = true })

-- Fallback for any other monitor (e.g. on another machine)
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
