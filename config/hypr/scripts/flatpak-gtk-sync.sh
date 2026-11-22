#!/usr/bin/env bash
# Flatpak sandboxes can't see ~/.config/gtk-4.0 (symlinks into the repo and
# /usr/share/themes), so libadwaita apps fall back to stock colours. Give every
# Flatpak app (existing and future) a real copy of the Catppuccin GTK4 theme in
# its private config dir. Safe to rerun; skips apps with their own gtk.css.
THEME="${GTK_THEME:-catppuccin-macchiato-mauve-standard+default}"
SRC="/usr/share/themes/$THEME/gtk-4.0"
RICE="$(dirname "$(readlink -f "$0")")/../../gtk-4.0"
MARK=".rice-synced"
[[ -d $SRC && -d $RICE ]] || exit 0

for app in "$HOME"/.var/app/*/; do
    dst="${app}config/gtk-4.0"
    [[ -e $dst/gtk.css && ! -e $dst/$MARK ]] && continue   # user's own theme
    mkdir -p "$dst" || continue
    rm -rf "$dst/assets"; cp -rL "$SRC/assets" "$dst/" 2>/dev/null
    cp -L "$RICE/overrides.css" "$dst/"
    for v in "" -dark; do
        cp -L "$SRC/gtk$v.css" "$dst/theme$v.css"
        sed 's#file://[^"]*/gtk\(-dark\)\?\.css#theme\1.css#' "$RICE/gtk$v.css" > "$dst/gtk$v.css"
    done
    touch "$dst/$MARK"
done
