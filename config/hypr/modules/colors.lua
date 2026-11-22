------------------
---- COLOURS -----
------------------

-- Catppuccin Macchiato — https://catppuccin.com/palette
-- GTK-CSS copy for waybar: config/theme/macchiato.css; rofi: config/rofi/themes/macchiato.rasi
--
--   local c = require("modules.colors")
--   c.rgba("mauve", "ee")  -> "rgba(c6a0f6ee)"

local M = {
    rosewater = "f4dbd6", flamingo = "f0c6c6", pink     = "f5bde6", mauve    = "c6a0f6",
    red       = "ed8796", maroon   = "ee99a0", peach    = "f5a97f", yellow   = "eed49f",
    green     = "a6da95", teal     = "8bd5ca", sky      = "91d7e3", sapphire = "7dc4e4",
    blue      = "8aadf4", lavender = "b7bdf8",
    text      = "cad3f5", subtext1 = "b8c0e0", subtext0 = "a5adcb",
    overlay2  = "939ab7", overlay1 = "8087a2", overlay0 = "6e738d",
    surface2  = "5b6078", surface1 = "494d64", surface0 = "363a4f",
    base      = "24273a", mantle   = "1e2030", crust    = "181926",
}

-- Rice accent — keep in sync with @accent / @accent2 in macchiato.css
M.accent  = "mauve"
M.accent2 = "blue"

-- name may be a palette colour ("mauve") or an alias ("accent")
function M.rgba(name, alpha)
    local hex = M[name]
    if M[hex] then hex = M[hex] end -- alias -> palette name -> hex
    assert(hex and hex:match("^%x%x%x%x%x%x$"), "unknown colour: " .. tostring(name))
    return "rgba(" .. hex .. (alpha or "ff") .. ")"
end

return M
