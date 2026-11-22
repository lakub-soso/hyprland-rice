#!/usr/bin/env bash
# Launcher (SUPER + Space): rofi with Apps · Calc · Files · Windows, plus a
# header with the user's avatar/name (→ mugshot) and a power button (→ wlogout).
# Pressing the bind again while it's open closes it.
pkill -x rofi && exit 0
dir="$HOME/.config/rofi/scripts"

# --- avatar + display name from AccountsService (what mugshot/SDDM use) ---
user_path=$(busctl --system call org.freedesktop.Accounts /org/freedesktop/Accounts \
    org.freedesktop.Accounts FindUserByName s "$USER" 2>/dev/null | sed -E 's/^o "(.*)"$/\1/')
prop() {  # prop <name> → string value or empty
    [[ -n $user_path ]] || return
    busctl --system get-property org.freedesktop.Accounts "$user_path" \
        org.freedesktop.Accounts.User "$1" 2>/dev/null | sed -E 's/^s "(.*)"$/\1/'
}
avatar="$HOME/.face"
[[ -s $avatar ]] || avatar="$(prop IconFile)"
[[ -n $avatar && -r $avatar ]] || avatar="avatar-default"   # Papirus icon name
name="$(prop RealName)"
[[ -n $name ]] || name="$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)"
[[ -n $name ]] || name="$USER"
esc() { local s=${1//\\/\\\\}; printf '%s' "${s//\"/\\\"}"; }

# One property per line: rofi's rasi parser breaks on two quoted strings on
# the same line.
theme_str="icon-avatar { filename: \"$(esc "$avatar")\"; }
button-user { content: \"$(esc "$name")\"; }"

exec rofi -show apps -theme launcher -theme-str "$theme_str" \
    -modi "apps:$dir/apps.py,calc,files:$dir/files.sh,window" \
    -calc-command "echo -n '{result}' | wl-copy"
