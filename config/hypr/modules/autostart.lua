-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.exec_cmd("systemctl --user start hyprpolkitagent")
hl.on("hyprland.start", function ()
--   hl.exec_cmd(terminal)
   hl.exec_cmd("nm-applet")
   hl.exec_cmd("solaar --window=hide")   -- Logitech devices: tray icon only
   hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
   hl.exec_cmd("waybar & hyprpaper")
   -- Root GUI apps started via pkexec (gparted) are X11 and run as root, which
   -- Xwayland refuses ("no authorization protocol specified"). Allow only
   -- local root, nothing else.
   hl.exec_cmd("xhost +si:localuser:root")
   -- Clipboard history (SUPER + V): record text and images with cliphist
   hl.exec_cmd("wl-paste --type text --watch cliphist store")
   hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
