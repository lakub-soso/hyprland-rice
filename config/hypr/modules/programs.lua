---------------------
---- MY PROGRAMS ----
---------------------

-- Shared values used by other modules: local programs = require("modules.programs")
return {
    terminal    = "kitty",
    fileManager = "dolphin",
    -- rofi launcher; pressing the bind again while it's open closes it.
    -- Launcher: Apps (categorised, Recent on top) · Calc (Enter copies) ·
    -- Files (fd search in ~) · Windows, with a header showing your avatar/name
    -- (→ mugshot) and a power button (→ wlogout). See config/rofi/.
    menu        = "~/.config/rofi/scripts/launcher.sh",
    power       = "~/.config/rofi/scripts/power.sh",
    clipboard   = "pkill -x rofi || ~/.config/rofi/scripts/clipboard.sh",

    mainMod     = "SUPER", -- Sets "Windows" key as main modifier
}
