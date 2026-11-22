#!/usr/bin/env bash
# rofi script mode "Files": fuzzy search over files in $HOME (via fd; skips
# dotfiles/dot-dirs and .gitignored files). Enter opens it with the default app.
# Header buttons / Alt+1..4 arrive as hot keys; apps.py handles them for both.
here="$(dirname "$(readlink -f "$0")")"
retv="${ROFI_RETV:-0}"
if (( retv >= 10 )); then
    "$here/apps.py" --hot-key "$retv"
    exit 0
fi
if (( retv == 1 )) && [[ -n ${1:-} ]]; then
    setsid -f xdg-open "$HOME/$1" >/dev/null 2>&1
    exit 0
fi
(( retv == 2 )) && exit 0   # Enter on text matching nothing: close
printf '\0use-hot-keys\x1ftrue\n'
printf '\0no-custom\x1ffalse\n'
fd --type f --base-directory "$HOME" . 2>/dev/null
