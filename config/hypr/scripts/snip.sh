#!/usr/bin/env bash
# Snipping tool (SUPER + SHIFT + S), à la Windows Snip & Sketch:
#   1. freeze the screen (hyprpicker, if installed)
#   2. drag to select a region, or click a window to grab the whole window
#   3. save to ~/Pictures/Screenshots and copy to the clipboard
#   4. notification — click it to annotate in satty (if installed)
# Esc cancels.
set -uo pipefail

# Real Pictures folder from user-dirs.dirs (xdg-user-dir prints $HOME if unset)
pictures="$(xdg-user-dir PICTURES 2>/dev/null)"
[[ -z $pictures || $pictures == "$HOME" ]] && pictures="$HOME/Pictures"
dir="$pictures/Screenshots"
file="$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
mkdir -p "$dir"

# Only one snip at a time — held only while selecting/capturing (released
# below). Everything started in the background gets `9>&-` so it does NOT
# inherit the lock: wl-copy keeps running to serve the clipboard and the
# notification waits for a click, and either holding fd 9 used to block every
# following snip (the "cooldown" / "sometimes nothing happens").
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/snip.lock"
flock -n 9 || exit 0

# Freeze the screen so menus/tooltips stay put while selecting
freeze_pid=""
if command -v hyprpicker >/dev/null; then
    hyprpicker -r -z >/dev/null 2>&1 9>&- &
    freeze_pid=$!
    sleep 0.15  # let the frozen frame map before slurp grabs input
fi
unfreeze() { [[ -n $freeze_pid ]] && kill "$freeze_pid" 2>/dev/null; freeze_pid=""; }
trap unfreeze EXIT

# Rectangles of windows on currently visible workspaces, fed to slurp so a
# single click selects a whole window ("x,y wxh" per line).
windows() {
    local active
    active="$(hyprctl monitors | awk '/active workspace:/{print $3} /special workspace:/{if ($3 ~ /^special/) print $3}')"
    hyprctl clients | awk -v active="$active" '
        BEGIN { n = split(active, a, "\n"); for (i = 1; i <= n; i++) vis[a[i]] = 1 }
        /^Window /        { at = size = ws = ""; mapped = 1; hidden = 0 }
        /^\tat: /         { at = $2 }
        /^\tsize: /       { size = $2 }
        /^\tworkspace: /  { ws = $2 }
        /^\tmapped: /     { mapped = $2 }
        /^\thidden: /     { hidden = $2 }
        /^\tfloating: /   { if (mapped && !hidden && (ws in vis)) { sub(",", "x", size); print at " " size } }
    '
}

geom="$(windows | slurp -d -b '#24273a66' -c '#c6a0f6ff' -s '#c6a0f622' -B '#c6a0f633' -w 2 2>/dev/null)" || exit 0
[[ -n $geom ]] || exit 0

grim -g "$geom" "$file" || { unfreeze; notify-send -u critical "Screenshot failed" "grim could not capture"; exit 1; }
unfreeze
flock -u 9; exec 9>&-          # capture done: next snip may start right away
wl-copy --type image/png < "$file"

# Notification with an "Edit" action (dunst: left-click runs the default action)
(
    if command -v satty >/dev/null; then
        action="$(notify-send -a Screenshot -i "$file" -A default=Edit -A edit=Edit \
            "Screenshot copied" "Saved to ${file/#$HOME/\~}\nClick to annotate")"
        if [[ $action == default || $action == edit ]]; then
            satty --filename "$file" --output-filename "$file" --copy-command wl-copy --early-exit
        fi
    else
        notify-send -a Screenshot -i "$file" "Screenshot copied" "Saved to ${file/#$HOME/\~}"
    fi
) >/dev/null 2>&1 9>&- &
disown
