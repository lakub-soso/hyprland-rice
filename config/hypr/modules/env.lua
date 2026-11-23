-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/

-- Cursor: Catppuccin Macchiato Mauve (AUR catppuccin-cursors-macchiato, XCursor
-- only, no hyprcursor build; Hyprland falls back to XCursor). Also set in GTK
-- settings.ini, gsettings (install.sh CURSOR_THEME) and ~/.icons/default.
hl.env("XCURSOR_THEME", "catppuccin-macchiato-mauve-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "catppuccin-macchiato-mauve-cursors")
hl.env("HYPRCURSOR_SIZE", "24")

-- Theming: Qt apps take their (Catppuccin) palette from qt6ct — config/qt6ct
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
