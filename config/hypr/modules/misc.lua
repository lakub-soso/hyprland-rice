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
---- RENDER ----
----------------

hl.config({
    render = {
        -- Hyprland switches the monitor into HDR whenever a fullscreen window
        -- asks for it (default 1).
        -- Set to 1 to get auto-HDR back for real HDR games.
        cm_auto_hdr = 0,
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
