-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Theming: Qt apps take their (Catppuccin) palette from qt6ct — config/qt6ct
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
