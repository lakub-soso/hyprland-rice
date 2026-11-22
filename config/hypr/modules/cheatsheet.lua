--------------------
---- CHEATSHEET ----
--------------------

-- Wraps hl.bind so every bind carries a description, and collects them into a
-- data file that the cheatsheet (SUPER + /) shows. Because the file is
-- regenerated on every config (re)load, it can never drift from the binds.
--
--   local cs = require("modules.cheatsheet")
--   cs.section("Apps")
--   cs.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"), "Terminal")
--   cs.bind(keys, action, desc, { hidden = true })  -- bind, but don't list it
--   cs.note("SUPER + 1-0", "Go to workspace")       -- list only (for loops)
--   cs.write()                                      -- call once, at the end
--
-- The file is plain data, one record per line (tab-separated):
--   S <tab> Section name
--   K <tab> SUPER + SHIFT + S <tab> Description
-- config/rofi/scripts/cheatsheet.py lays it out: symbolic keycaps (❖ ⇧ ⌃ …),
-- fullscreen, whole sections packed into columns to fit the monitor.

local M = {}

M.path = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-cheatsheet.tsv"

local lines = {}
local function clean(s) return (s:gsub("[\t\n]", " ")) end

function M.section(name)
    table.insert(lines, "S\t" .. clean(name))
end

function M.note(keys, desc)
    table.insert(lines, "K\t" .. clean(keys) .. "\t" .. clean(desc))
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

-- Toggles the cheatsheet (pressing the bind again closes it).
M.command = "~/.config/rofi/scripts/cheatsheet.py " .. M.path

return M
