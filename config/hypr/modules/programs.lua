---------------------
---- MY PROGRAMS ----
---------------------

-- Shared values used by other modules: local programs = require("modules.programs")
return {
    terminal    = "kitty",
    fileManager = "dolphin",
    -- Toggle: pressing the bind again while wofi is open closes it.
    -- Mode/look come from config/wofi/{config,style.css}.
    menu        = "pkill -x wofi || wofi --show drun",

    mainMod     = "SUPER", -- Sets "Windows" key as main modifier
}
