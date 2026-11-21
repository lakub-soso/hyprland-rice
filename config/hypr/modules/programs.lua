---------------------
---- MY PROGRAMS ----
---------------------

-- Shared values used by other modules: local programs = require("modules.programs")
return {
    terminal    = "kitty",
    fileManager = "dolphin",
    -- Toggle: pressing the bind again while wofi is open closes it.
    -- Mode/look come from config/wofi/{config,style.css}.
    -- (cd so wofi's style.css can @import ../theme/macchiato.css)
    menu        = "pkill -x wofi || (cd ~/.config/wofi && wofi --show drun)",

    mainMod     = "SUPER", -- Sets "Windows" key as main modifier
}
