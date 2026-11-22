#!/usr/bin/env bash
# Power menu overlay (launcher power button, SUPER + Escape): wlogout,
# configured in config/wlogout/. Pressing it again closes it.
pkill -x wlogout && exit 0

# wlogout's margins are in pixels, so centre the single row of buttons on the
# focused monitor: read its mode (WxH) and rotation from hyprctl.
read -r w h t <<<"$(hyprctl monitors | awk '
    /^Monitor/              { res = ""; tr = 0 }
    /^\t[0-9]+x[0-9]+@/     { res = $1 }
    /^\ttransform:/         { tr = $2 }
    /^\tfocused: yes/       { split(res, a, /[x@]/); print a[1], a[2], tr; exit }')"
# rotated 90°/270° (portrait): the visible height is the mode's width
[[ $t == 1 || $t == 3 ]] && h=$w
h=${h:-1440}
margin=$(( (h - 220) / 2 ))

exec wlogout --protocol layer-shell --buttons-per-row 5 \
    --margin-top "$margin" --margin-bottom "$margin" \
    --column-spacing 16 --row-spacing 16
