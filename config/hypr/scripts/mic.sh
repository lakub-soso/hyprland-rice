#!/usr/bin/env bash
# Microphone indicator + mute.
#   mic.sh          → waybar custom/mic: prints JSON whenever audio changes.
#                     Shown only while an app records from a real microphone
#                     (sources ending in .monitor = "desktop audio" capture,
#                     and pavucontrol's level meters, don't count).
#   mic.sh toggle   → mute/unmute the default mic + notification
#                     (SUPER + SHIFT + M, mic mute key, clicking the waybar icon)

ICON_LIVE=$'\U000f036c'    # nf-md-microphone
ICON_MUTED=$'\U000f036d'   # nf-md-microphone_off

is_muted() { wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED; }

if [[ ${1:-} == toggle ]]; then
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    if is_muted; then
        notify-send -a Microphone -i microphone-sensitivity-muted \
            -h string:x-dunst-stack-tag:mic "Microphone muted"
    else
        notify-send -a Microphone -i audio-input-microphone \
            -h string:x-dunst-stack-tag:mic "Microphone on"
    fi
    exit 0
fi

# Apps currently recording from a real (non-monitor) input, comma-separated
recording_apps() {
    jq -rn \
        --argjson sources "$(pactl -f json list sources 2>/dev/null || echo '[]')" \
        --argjson outputs "$(pactl -f json list source-outputs 2>/dev/null || echo '[]')" '
        ($sources | map(select(.name | endswith(".monitor") | not) | .index)) as $mics
        | $outputs
        | map(select(.source as $s | $mics | index($s)))
        | map(.properties["application.name"] // "unknown")
        | map(select(. != "PulseAudio Volume Control" and . != "pavucontrol"))
        | unique | join(", ")'
}

emit() {
    local apps
    apps="$(recording_apps)"
    if [[ -z $apps ]]; then
        echo '{"text": ""}'                 # empty text → waybar hides the module
    elif is_muted; then
        jq -cn --arg t "$ICON_MUTED" --arg a "$apps" \
            '{text: $t, class: "muted", tooltip: "Microphone MUTED — in use by \($a)\nClick to unmute"}'
    else
        jq -cn --arg t "$ICON_LIVE" --arg a "$apps" \
            '{text: $t, class: "live", tooltip: "Microphone live — in use by \($a)\nClick to mute"}'
    fi
}

emit
# Re-check whenever streams or sources change (incl. mute toggles)
pactl subscribe 2>/dev/null | while read -r line; do
    case $line in
        *source-output*|*"on source"*|*"on server"*) emit ;;
    esac
done
