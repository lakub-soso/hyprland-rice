#!/usr/bin/env bash
# Color picker (SUPER + SHIFT + C, like PowerToys): click any pixel on any
# screen → its hex code is copied, and a notification shows a swatch plus
# rgb()/hsl(). Esc cancels. Uses hyprpicker (also used by the snip tool).
pgrep -x hyprpicker >/dev/null && exit 0

# No --quiet: hyprpicker prints the picked colour through its logger, and
# --quiet suppresses everything but errors — including the colour. Other log
# lines may appear too, so take the last hex code in the output.
hex="$(hyprpicker --render-inactive --no-fancy --format=hex 2>/dev/null \
       | grep -oE '#[0-9A-Fa-f]{6}' | tail -n1)"
[[ -n $hex ]] || exit 0     # cancelled (Esc)
wl-copy --trim-newline "$hex"

r=$((16#${hex:1:2})) g=$((16#${hex:3:2})) b=$((16#${hex:5:2}))
hsl=$(awk -v r="$r" -v g="$g" -v b="$b" 'BEGIN {
    r/=255; g/=255; b/=255
    mx = r > g ? (r > b ? r : b) : (g > b ? g : b)
    mn = r < g ? (r < b ? r : b) : (g < b ? g : b)
    l = (mx + mn) / 2; d = mx - mn; h = 0; s = 0
    if (d > 0) {
        s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
        if (mx == r)      h = (g - b) / d + (g < b ? 6 : 0)
        else if (mx == g) h = (b - r) / d + 2
        else              h = (r - g) / d + 4
        h *= 60
    }
    printf "hsl(%d, %d%%, %d%%)", h + 0.5, s * 100 + 0.5, l * 100 + 0.5 }')

# dunst renders Pango markup: the swatch is a run of spaces on that background
notify-send -a "Color picker" -h string:x-dunst-stack-tag:colorpicker \
    "$hex copied" \
    "<span background='$hex'>                    </span>
rgb($r, $g, $b)
$hsl"
