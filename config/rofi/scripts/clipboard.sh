#!/usr/bin/env bash
# Clipboard history picker (SUPER + V): cliphist entries in rofi; the chosen one
# goes back on the clipboard. History is recorded by the wl-paste watchers in
# hypr/modules/autostart.lua. Clear it with: cliphist wipe
sel="$(cliphist list | rofi -dmenu -i -p Clipboard -display-columns 2 -no-custom)" || exit 0
[[ -n $sel ]] || exit 0
printf '%s' "$sel" | cliphist decode | wl-copy
