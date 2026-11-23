-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/
-- Permission changes need a Hyprland restart (not applied on reload, for
-- security reasons).
--
-- With enforcement on, a client that isn't listed here gets a popup asking
-- whether it may capture the screen (screencopy) or load a plugin. Without
-- it, any Wayland client could silently read the screen.
-- Screen sharing in browsers, Discord, OBS, Steam… goes through the portal
-- (xdg-desktop-portal-hyprland), which has its own picker, so it's allowed.

hl.config({
    ecosystem = {
        enforce_permissions = true,
    },
})

local allow_screencopy = {
    "/usr/(bin|local/bin)/grim",                                -- snip.sh
    "/usr/(bin|local/bin)/hyprpicker",                          -- snip.sh freeze + colorpicker.sh
    "/usr/(bin|local/bin)/hyprlock",                            -- hyprlock.conf `path = screenshot`
    "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland",     -- screen sharing via the portal
}
for _, binary in ipairs(allow_screencopy) do
    hl.permission({ binary = binary, type = "screencopy", mode = "allow" })
end

-- No plugins are used. Uncomment if you start using hyprpm:
-- hl.permission({ binary = "/usr/(bin|local/bin)/hyprpm", type = "plugin", mode = "allow" })
