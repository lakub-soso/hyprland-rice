--------------------
---- CHEATSHEET ----
--------------------

-- Wraps hl.bind so every bind carries a description, and collects them into a
-- text file that the cheatsheet keybind shows in wofi. Because the file is
-- regenerated on every config (re)load, it can never drift from the binds.
--
--   local cs = require("modules.cheatsheet")
--   cs.section("Apps")
--   cs.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"), "Terminal")
--   cs.bind(keys, action, desc, { hidden = true })  -- bind, but don't list it
--   cs.note("SUPER + 1-0", "Go to workspace")       -- list only (for loops)
--   cs.write()                                      -- call once, at the end

local M = {}

M.path = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-cheatsheet.txt"

local lines = {}
local KEY_WIDTH = 28

-- "SUPER + SHIFT + mouse:272" -> "Super + Shift + LMB"
local pretty = {
    SUPER = "Super", SHIFT = "Shift", CTRL = "Ctrl", ALT = "Alt",
    space = "Space", left = "←", right = "→", up = "↑", down = "↓",
    slash = "/", Return = "Enter",
    ["mouse:272"] = "LMB drag", ["mouse:273"] = "RMB drag",
    mouse_down = "Scroll ↓", mouse_up = "Scroll ↑",
    XF86AudioRaiseVolume = "Volume Up key", XF86AudioLowerVolume = "Volume Down key",
    XF86AudioMute = "Mute key", XF86AudioMicMute = "Mic Mute key",
    XF86AudioPlay = "Play key", XF86AudioPause = "Pause key",
    XF86AudioNext = "Next key", XF86AudioPrev = "Prev key",
    XF86MonBrightnessUp = "Brightness Up key", XF86MonBrightnessDown = "Brightness Down key",
}
local function prettify(keys)
    return (keys:gsub("[%w_:]+", function(tok) return pretty[tok] or tok end))
end

function M.section(name)
    if #lines > 0 then table.insert(lines, "") end
    table.insert(lines, "── " .. name .. " ──")
end

function M.note(keys, desc)
    local k = prettify(keys)
    -- pad by characters, not bytes, so "←" etc. don't break the column
    local pad = math.max(1, KEY_WIDTH + 1 - (utf8.len(k) or #k))
    table.insert(lines, "  " .. k .. string.rep(" ", pad) .. desc)
end

function M.bind(keys, action, desc, opts)
    opts = opts or {}
    local hidden = opts.hidden
    opts.hidden = nil
    opts.description = desc
    if not hidden then M.note(keys, desc) end
    return hl.bind(keys, action, opts)
end

function M.write()
    local f, err = io.open(M.path, "w")
    if not f then
        hl.exec_cmd("notify-send 'Cheatsheet' " .. string.format("%q", "could not write: " .. tostring(err)))
        return
    end
    f:write(table.concat(lines, "\n"), "\n")
    f:close()
end

-- Shell command that toggles the cheatsheet window. The cd is needed because
-- wofi resolves cheatsheet.css's @import relative to the working directory.
M.command = "pkill -x wofi || (cd ~/.config/wofi && wofi --dmenu --prompt 'Keybinds'"
    .. " --width 720 --height 680 --style cheatsheet.css --cache-file /dev/null"
    .. " < " .. M.path .. " >/dev/null)"

return M
