#!/usr/bin/env bash
# Reproducible Hyprland rice bootstrap.
#
#   ./install.sh              # packages + link + services (everything)
#   ./install.sh packages     # install packages/pacman.txt + packages/aur.txt
#   ./install.sh packages --hardware   # ...plus packages/hardware.txt
#   ./install.sh link         # symlink config/* into ~/.config (backs up existing)
#   ./install.sh unlink       # remove symlinks that point into this repo
#   ./install.sh services     # enable system/user services
#   ./install.sh dirs         # create ~/Pictures, ~/Videos, … (xdg-user-dirs)
#   ./install.sh system       # copy system/ into / with sudo (e.g. SDDM theme)
#   ./install.sh theme        # apply dark-mode gsettings (dconf)
#   ./install.sh diff         # show packages installed but not tracked (and vice versa)
#
# Add DRY_RUN=1 to print what would happen without changing anything.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DST="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DST="${XDG_DATA_HOME:-$HOME/.local/share}"
# Repo dir -> where its files get symlinked
LINK_TREES=("$REPO/config:$CONFIG_DST" "$REPO/data:$DATA_DST")
KDE_SCHEME="CatppuccinMacchiatoMauve"
ICON_THEME="Papirus-Dark"
GTK_THEME="catppuccin-macchiato-mauve-standard+default"   # from catppuccin-gtk-theme-macchiato
FOLDER_COLOR="cat-macchiato-mauve"   # from papirus-folders-catppuccin-git
DRY_RUN="${DRY_RUN:-0}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
run()  { if [[ $DRY_RUN == 1 ]]; then echo "  [dry] $*"; else "$@"; fi; }

# Read a package list, stripping comments and blank lines.
read_list() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"; }

ensure_yay() {
    command -v yay >/dev/null && return
    log "Bootstrapping yay"
    local tmp; tmp="$(mktemp -d)"
    run sudo pacman -S --needed --noconfirm git base-devel
    run git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && run makepkg -si --noconfirm)
    rm -rf "$tmp"
}

# DaVinci Resolve (AUR davinci-resolve). Blackmagic gates the download behind a
# registration form, so the PKGBUILD can't fetch its source: the zip must sit
# next to the PKGBUILD. We look for the exact version the AUR package expects
# in ~/Downloads; if it's there, build it, otherwise say where to get it.
install_davinci() {
    pacman -Q davinci-resolve &>/dev/null && return 0
    local ver dl zip tmp
    ver="$(yay -Si --aur davinci-resolve 2>/dev/null | awk -F': ' '/^Version/{print $2}' | cut -d- -f1)"
    if [[ -z $ver ]]; then
        warn "DaVinci Resolve: couldn't query the AUR — skipping"
        return 0
    fi
    dl="$(xdg-user-dir DOWNLOAD 2>/dev/null)"
    [[ -z $dl || $dl == "$HOME" ]] && dl="$HOME/Downloads"
    zip="$dl/DaVinci_Resolve_${ver}_Linux.zip"
    if [[ ! -f $zip ]]; then
        warn "DaVinci Resolve $ver: download the free 'DaVinci Resolve' (not Studio) Linux zip from"
        warn "  https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion"
        warn "  save it as $zip and re-run ./install.sh packages"
        return 0
    fi
    # Build on disk, NOT in /tmp: /tmp is a RAM-backed tmpfs (half of RAM) and
    # unpacking Resolve needs ~20 GB at peak — it fills up and the extraction
    # gets truncated ("gzip: unexpected end of file" in prepare()).
    local build_root="${XDG_CACHE_HOME:-$HOME/.cache}/hyprland-rice"
    run mkdir -p "$build_root"
    local free_gb
    free_gb=$(df -BG --output=avail "$build_root" 2>/dev/null | tail -1 | tr -dc '0-9')
    if [[ -n $free_gb ]] && ((free_gb < 25)); then
        warn "DaVinci Resolve: only ${free_gb} GB free in $build_root, building needs ~25 GB — skipping"
        return 0
    fi
    log "Building DaVinci Resolve $ver from $zip (in $build_root)"
    tmp="$(mktemp -d -p "$build_root" davinci-resolve.XXXXXX)"
    run git clone https://aur.archlinux.org/davinci-resolve.git "$tmp/davinci-resolve"
    run cp "$zip" "$tmp/davinci-resolve/"
    # makepkg verifies the zip's sha256 against the PKGBUILD
    (cd "$tmp/davinci-resolve" && run makepkg -si --needed) || warn "DaVinci Resolve build failed"
    rm -rf "$tmp"
}

cmd_packages() {
    local lists=("$REPO/packages/pacman.txt") aur_lists=("$REPO/packages/aur.txt")
    local arg
    for arg in "$@"; do
        case "$arg" in
            --hardware) lists+=("$REPO/packages/hardware.txt") ;;
            *) warn "unknown option: $arg"; return 1 ;;
        esac
    done

    log "Installing repo packages"
    mapfile -t pkgs < <(cat "${lists[@]}" | sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d')
    run sudo pacman -S --needed "${pkgs[@]}"

    mapfile -t aur < <(cat "${aur_lists[@]}" | sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d')
    if ((${#aur[@]})); then
        ensure_yay
        log "Installing AUR packages"
        run yay -S --needed "${aur[@]}"
    fi

    install_davinci

    # Flatpaks (system-wide, from Flathub). flatpak itself comes from pacman.txt.
    mapfile -t flatpaks < <(read_list "$REPO/packages/flatpak.txt")
    if ((${#flatpaks[@]})); then
        if ! command -v flatpak >/dev/null && [[ $DRY_RUN != 1 ]]; then
            warn "flatpak not installed — skipping packages/flatpak.txt"
            return
        fi
        log "Installing Flatpaks from Flathub"
        run sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        run sudo flatpak install --system --noninteractive flathub "${flatpaks[@]}"
    fi
}

# Link every file individually (config/<app>/<file> -> ~/.config/<app>/<file>,
# data/... -> ~/.local/share/...), so apps can still write their own untracked
# files next to ours.
cmd_link() {
    local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
    local tree src_root dst_root backup_dir src rel dst
    for tree in "${LINK_TREES[@]}"; do
        src_root="${tree%%:*}"; dst_root="${tree#*:}"
        [[ -d $src_root ]] || continue
        backup_dir="$dst_root/.rice-backup-$stamp"
        while IFS= read -r -d '' src; do
            rel="${src#"$src_root"/}"
            dst="$dst_root/$rel"
            if [[ -L $dst && $(readlink -f "$dst") == "$(readlink -f "$src")" ]]; then
                continue  # already linked
            fi
            if [[ -e $dst || -L $dst ]]; then
                log "Backing up $dst -> $backup_dir/$rel"
                run mkdir -p "$(dirname "$backup_dir/$rel")"
                run mv "$dst" "$backup_dir/$rel"
            fi
            run mkdir -p "$(dirname "$dst")"
            run ln -s "$src" "$dst"
            log "Linked $dst"
        done < <(find "$src_root" -type f -not -path "*/__pycache__/*" -print0)
    done
}

cmd_unlink() {
    local tree src_root dst_root src dst
    for tree in "${LINK_TREES[@]}"; do
        src_root="${tree%%:*}"; dst_root="${tree#*:}"
        [[ -d $src_root ]] || continue
        while IFS= read -r -d '' src; do
            dst="$dst_root/${src#"$src_root"/}"
            if [[ -L $dst && $(readlink -f "$dst") == "$(readlink -f "$src")" ]]; then
                run rm "$dst"
                log "Unlinked $dst"
            fi
        done < <(find "$src_root" -type f -not -path "*/__pycache__/*" -print0)
    done
}

# System files: system/<path> is COPIED to /<path> (root-owned, 644). Copied
# rather than symlinked because system daemons (e.g. sddm) can't read $HOME.
# Re-run after editing anything under system/. Unchanged files are skipped;
# a differing existing file is kept as <file>.rice-bak first.
cmd_system() {
    local root="$REPO/system" src dst
    [[ -d $root ]] || return 0
    while IFS= read -r -d '' src; do
        dst="/${src#"$root"/}"
        if [[ -f $dst ]] && cmp -s "$src" "$dst"; then
            continue
        fi
        if [[ -e $dst ]]; then
            log "Backing up $dst -> $dst.rice-bak"
            run sudo cp -a "$dst" "$dst.rice-bak"
        fi
        log "Installing $dst (needs sudo)"
        run sudo install -Dm644 "$src" "$dst"
    done < <(find "$root" -type f -print0)

    # Wallpapers also go somewhere the sddm user can read (login background).
    local wp dst_wp
    for wp in "$REPO"/data/wallpapers/*; do
        [[ -f $wp ]] || continue
        dst_wp="/usr/share/backgrounds/hyprland-rice/$(basename "$wp")"
        [[ -f $dst_wp ]] && cmp -s "$wp" "$dst_wp" && continue
        log "Installing $dst_wp (needs sudo)"
        run sudo install -Dm644 "$wp" "$dst_wp"
    done

    ensure_locales
}

# Generate every locale named in system/etc/locale.conf (e.g. en_GB.UTF-8 for
# LC_TIME) by uncommenting it in /etc/locale.gen and running locale-gen.
ensure_locales() {
    local conf="$REPO/system/etc/locale.conf" loc norm changed=0
    [[ -f $conf ]] || return 0
    while IFS= read -r loc; do
        # `locale -a` lists en_GB.UTF-8 as en_GB.utf8
        norm="$(sed 's/\.UTF-8$/.utf8/' <<<"$loc")"
        locale -a 2>/dev/null | grep -qxF "$norm" && continue
        if ! grep -qE "^#? *${loc//./\\.} UTF-8" /etc/locale.gen; then
            warn "$loc not found in /etc/locale.gen — skipping"
            continue
        fi
        log "Enabling locale $loc (needs sudo)"
        run sudo sed -i -E "s/^# *(${loc//./\\.} UTF-8)/\\1/" /etc/locale.gen
        changed=1
    done < <(sed -nE 's/^(LANG|LC_[A-Z]+)=//p' "$conf" | sort -u)
    if ((changed)); then
        log "Generating locales"
        run sudo locale-gen
    fi
}

cmd_services() {
    log "Enabling services"
    run sudo systemctl enable NetworkManager.service bluetooth.service sddm.service
    run systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service \
        gnome-keyring-daemon.socket
}

# Standard home folders (Desktop, Documents, Downloads, Music, Pictures, Public,
# Templates, Videos) + ~/.config/user-dirs.dirs, as Plasma would set up.
cmd_dirs() {
    if ! command -v xdg-user-dirs-update >/dev/null; then
        warn "xdg-user-dirs not installed — run ./install.sh packages first"
        return
    fi
    log "Creating XDG user folders"
    run xdg-user-dirs-update

    # Dolphin builds its sidebar ("Places") once, on first launch, from the
    # folders that existed then, and never adds new ones. If it was created
    # before the folders above, back it up so Dolphin regenerates the defaults.
    local places="$DATA_DST/user-places.xbel" pictures
    pictures="$(xdg-user-dir PICTURES 2>/dev/null)"
    if [[ -f $places && -n $pictures ]] && ! grep -q "file://$pictures\"" "$places"; then
        log "Dolphin's Places predate the XDG folders — backing up so it regenerates"
        run mv "$places" "$places.bak-$(date +%Y%m%d-%H%M%S)"
    fi
}

# Settings that live in dconf rather than files. GTK4/libadwaita apps, Firefox,
# Electron apps and xdg portals read color-scheme from here to pick dark mode.
cmd_theme() {
    # Papirus folder colour. papirus-folders edits /usr/share/icons, hence sudo;
    # skipped when already applied. The package's pacman hook keeps it applied
    # across papirus-icon-theme updates.
    if command -v papirus-folders >/dev/null; then
        if papirus-folders -l --theme "$ICON_THEME" 2>/dev/null | grep -qE "^\s*>\s*$FOLDER_COLOR\s*$"; then
            log "Papirus folders already $FOLDER_COLOR"
        else
            log "Setting Papirus folders to $FOLDER_COLOR (needs sudo)"
            run sudo papirus-folders -C "$FOLDER_COLOR" --theme "$ICON_THEME"
        fi
    else
        warn "papirus-folders not installed — run ./install.sh packages first"
    fi

    log "Applying dark theme settings (gsettings)"
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    run gsettings set org.gnome.desktop.interface gtk-theme    "$GTK_THEME"
    run gsettings set org.gnome.desktop.interface icon-theme   "$ICON_THEME"
    run gsettings set org.gnome.desktop.interface font-name    'Noto Sans 11'

    # libadwaita apps ignore gtk-theme; they only load ~/.config/gtk-4.0/gtk.css
    # (and gtk-dark.css). Those two are ours (config/gtk-4.0/, linked by
    # `link`): they @import the theme's CSS + overrides.css. Here we only link
    # the theme's assets folder, which points into /usr/share/themes.
    local gtk4_src="/usr/share/themes/$GTK_THEME/gtk-4.0" item
    if [[ -d $gtk4_src ]]; then
        log "Linking $GTK_THEME GTK4 CSS for libadwaita apps"
        run mkdir -p "$CONFIG_DST/gtk-4.0"
        for item in assets; do
            [[ -e $gtk4_src/$item ]] && run ln -sfn "$gtk4_src/$item" "$CONFIG_DST/gtk-4.0/$item"
        done
    else
        warn "$GTK_THEME not installed — run ./install.sh packages first"
    fi

    # KDE apps (Dolphin…) ignore the qt6ct palette. They need (1) the colours in
    # kdeglobals, and (2) the app's own colour scheme pointed at our .colors file
    # (otherwise KColorSchemeManager resets them to light). kdeglobals is merged
    # key-by-key rather than symlinked, because KDE apps write their own
    # settings into it.
    local scheme="$REPO/data/color-schemes/$KDE_SCHEME.colors"
    if ! command -v kwriteconfig6 >/dev/null; then
        warn "kwriteconfig6 not found (comes with kconfig) — skipping KDE colours"
        return
    fi
    log "Merging $KDE_SCHEME into kdeglobals"
    local line group="" key val
    while IFS= read -r line; do
        [[ $line =~ ^\[(.*)\]$ ]] && { group="${BASH_REMATCH[1]}"; continue; }
        [[ $line =~ ^([^#=][^=]*)=(.*)$ && -n $group ]] || continue
        key="${BASH_REMATCH[1]}"; val="${BASH_REMATCH[2]}"
        # "--" so values like "-1" aren't parsed as options
        run kwriteconfig6 --file kdeglobals --group "$group" --key "$key" -- "$val"
    done < "$scheme"
    run kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICON_THEME"

    log "Pointing KDE apps at the $KDE_SCHEME colour scheme"
    local app
    for app in dolphin; do
        run kwriteconfig6 --file "${app}rc" --group UiSettings --key ColorScheme "$KDE_SCHEME"
    done
}

cmd_diff() {
    local tracked
    tracked="$(cat "$REPO"/packages/{pacman,aur,hardware}.txt | sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' | sort -u)"
    # Always-present base packages that don't belong in the rice lists.
    local ignore='^(base|base-devel|linux|linux-firmware|mkinitcpio|sudo|git|nano|vim|wget|iwd|polkit-kde-agent|yay|yay-debug)$'
    echo "Installed but NOT tracked (add to a list, or ignore):"
    comm -23 <(pacman -Qqe | grep -Ev "$ignore" | sort) <(echo "$tracked") | sed 's/^/  + /'
    echo "Tracked but NOT installed:"
    comm -13 <(pacman -Qq | sort) <(echo "$tracked") | sed 's/^/  - /'  # -Qq: deps count as installed

    if command -v flatpak >/dev/null; then
        local fp_tracked fp_installed
        fp_tracked="$(read_list "$REPO/packages/flatpak.txt" | sort -u)"
        fp_installed="$(flatpak list --app --columns=application 2>/dev/null | sort -u)"
        echo "Flatpaks installed but NOT tracked:"
        comm -23 <(echo "$fp_installed") <(echo "$fp_tracked") | sed '/^$/d; s/^/  + /'
        echo "Flatpaks tracked but NOT installed:"
        comm -13 <(echo "$fp_installed") <(echo "$fp_tracked") | sed '/^$/d; s/^/  - /'
    fi
}

main() {
    local cmd="${1:-all}"; shift || true
    case "$cmd" in
        all)      cmd_packages "$@"; cmd_link; cmd_dirs; cmd_system; cmd_services; cmd_theme ;;
        packages) cmd_packages "$@" ;;
        link)     cmd_link ;;
        unlink)   cmd_unlink ;;
        services) cmd_services ;;
        dirs)     cmd_dirs ;;
        system)   cmd_system ;;
        theme)    cmd_theme ;;
        diff)     cmd_diff ;;
        *) sed -n '2,16p' "$0"; exit 1 ;;
    esac
}
main "$@"
