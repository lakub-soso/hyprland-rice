-- Hyprland entry point. Each section lives in modules/<name>.lua.
-- See https://wiki.hypr.land/configuring/

local modules = {
    "monitors",
    "autostart",
    "env",
    "permissions",
    "appearance",
    "animations",
    "layouts",
    "misc",
    "input",
    "keybinds",
    "rules",
}

for _, name in ipairs(modules) do
    require("modules." .. name)
end

-- Optional per-machine overrides, not tracked in the repo: ~/.config/hypr/local.lua
if package.searchpath("local", package.path) then
    require("local")
end
