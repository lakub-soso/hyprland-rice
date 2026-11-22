#!/usr/bin/env bash
# Mark the main monitor as XWayland's RandR *primary* output.
#
# XWayland has no primary by default and lists outputs in connector order;
# X11/Proton games then treat the first output as the primary display (with
# the Samsung on the lower port they defaulted to 1080x1920 on the wrong
# screen). The cabling now puts the Philips first (modules/monitors.lua);
# this keeps games right whatever the port order.
# Main monitor = the one Hyprland places at 0x0 (modules/monitors.lua);
# else the biggest.
#
# Run at startup and on monitor hotplug (modules/autostart.lua). XWayland may
# not have its outputs yet right after login, so retry for a few seconds.

main=$(hyprctl monitors -j | jq -r '
    (map(select(.x == 0 and .y == 0)) | first // empty).name
    // (max_by(.width * .height)).name')
[[ -n $main ]] || exit 0

for _ in $(seq 1 20); do
    if xrandr --output "$main" --primary 2>/dev/null \
        && xrandr 2>/dev/null | grep -q "^$main connected primary"; then
        exit 0
    fi
    sleep 0.5
done
echo "xwayland-primary: couldn't set $main as primary" >&2
exit 1
