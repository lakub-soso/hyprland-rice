#!/usr/bin/env bash
# Reproducible Hyprland rice bootstrap.
#
#   ./install.sh              # packages + link + services (everything)
#   ./install.sh packages     # install packages/pacman.txt + packages/aur.txt
#   ./install.sh packages --hardware   # ...plus packages/hardware.txt
#   ./install.sh link         # symlink config/* into ~/.config (backs up existing)
#   ./install.sh unlink       # remove symlinks that point into this repo
#   ./install.sh services     # enable system/user services
#   ./install.sh diff         # show packages installed but not tracked (and vice versa)
#
# Add DRY_RUN=1 to print what would happen without changing anything.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$REPO/config"
CONFIG_DST="${XDG_CONFIG_HOME:-$HOME/.config}"
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

cmd_packages() {
    local lists=("$REPO/packages/pacman.txt")
    [[ ${1:-} == --hardware ]] && lists+=("$REPO/packages/hardware.txt")

    log "Installing repo packages"
    mapfile -t pkgs < <(cat "${lists[@]}" | sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d')
    run sudo pacman -S --needed "${pkgs[@]}"

    mapfile -t aur < <(read_list "$REPO/packages/aur.txt")
    if ((${#aur[@]})); then
        ensure_yay
        log "Installing AUR packages"
        run yay -S --needed "${aur[@]}"
    fi
}

# Link every top-level entry of config/<app>/<file> individually, so apps can
# still write their own untracked files next to ours inside ~/.config/<app>.
cmd_link() {
    local backup_dir="$CONFIG_DST/.rice-backup-$(date +%Y%m%d-%H%M%S)"
    local src rel dst
    while IFS= read -r -d '' src; do
        rel="${src#"$CONFIG_SRC"/}"
        dst="$CONFIG_DST/$rel"
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
        log "Linked $rel"
    done < <(find "$CONFIG_SRC" -type f -print0)
}

cmd_unlink() {
    local src dst
    while IFS= read -r -d '' src; do
        dst="$CONFIG_DST/${src#"$CONFIG_SRC"/}"
        if [[ -L $dst && $(readlink -f "$dst") == "$(readlink -f "$src")" ]]; then
            run rm "$dst"
            log "Unlinked $dst"
        fi
    done < <(find "$CONFIG_SRC" -type f -print0)
}

cmd_services() {
    log "Enabling services"
    run sudo systemctl enable NetworkManager.service bluetooth.service sddm.service
    run systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service \
        gnome-keyring-daemon.socket
}

cmd_diff() {
    local tracked
    tracked="$(cat "$REPO"/packages/*.txt | sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' | sort -u)"
    # Always-present base packages that don't belong in the rice lists.
    local ignore='^(base|base-devel|linux|linux-firmware|mkinitcpio|sudo|git|nano|vim|wget|iwd|polkit-kde-agent|yay|yay-debug)$'
    echo "Installed but NOT tracked (add to a list, or ignore):"
    comm -23 <(pacman -Qqe | grep -Ev "$ignore" | sort) <(echo "$tracked") | sed 's/^/  + /'
    echo "Tracked but NOT installed:"
    comm -13 <(pacman -Qqe | sort) <(echo "$tracked") | sed 's/^/  - /'
}

main() {
    local cmd="${1:-all}"; shift || true
    case "$cmd" in
        all)      cmd_packages "$@"; cmd_link; cmd_services ;;
        packages) cmd_packages "$@" ;;
        link)     cmd_link ;;
        unlink)   cmd_unlink ;;
        services) cmd_services ;;
        diff)     cmd_diff ;;
        *) sed -n '2,13p' "$0"; exit 1 ;;
    esac
}
main "$@"
