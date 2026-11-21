----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(

        -- If hyprlock ever crashes, the session stays locked (safe), and this
        -- lets you start a new hyprlock from a TTY (Ctrl+Alt+F3, log in):
        --   hyprctl --instance 0 dispatch "hl.dsp.exec_cmd('hyprlock')"
        allow_session_lock_restore = true,
    },
})


----------------
---- LAYERS ----
----------------

hl.config({
    layers = {
        allow_new_top_layers_over_existing_fullscreen = true, -- Set to false to make newly mapped top layers render below existing covering fullscreen window
    },
})
