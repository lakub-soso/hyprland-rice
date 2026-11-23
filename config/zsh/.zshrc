# zsh config — ported from github.com/lakub-soso/arch-personal-setup (.zshrc).
# Loaded via ZDOTDIR=~/.config/zsh (set in ~/.zshenv, repo: home/.zshenv).
# Prompt: Starship (config/starship.toml) instead of Powerlevel10k, whose
# README now says it has "very limited support".

export PATH="$HOME/.local/bin:$PATH"

# --- zinit (installs itself on first run) ------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[ ! -d "$ZINIT_HOME" ] && mkdir -p "$(dirname "$ZINIT_HOME")"
[ ! -d "$ZINIT_HOME/.git" ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "$ZINIT_HOME/zinit.zsh"

# --- plugins -----------------------------------------------------------------
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting   # must be the last plugin (its docs)

# oh-my-zsh snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo                  # Esc Esc: prefix the line with sudo
zinit snippet OMZP::archlinux             # pacman/yay aliases
zinit snippet OMZP::command-not-found     # "install X with pacman -S …" (needs pkgfile)
zinit snippet OMZP::npm

# --- completions -------------------------------------------------------------
mkdir -p "$XDG_CACHE_HOME/zsh"
autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
autoload -U select-word-style
select-word-style bash
zinit cdreplay -q

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# --- keybindings -------------------------------------------------------------
# Force emacs mode: EDITOR=nvim makes zsh default to vi mode, where Esc-prefixed
# keys (Alt+Backspace, Alt+arrows) switch to command mode instead.
bindkey -e
bindkey '^[^?' backward-kill-word  # Alt+Backspace
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[[1;3C' forward-word     # Alt+→
bindkey '^[[1;3D' backward-word    # Alt+←
bindkey '^[[1;5C' forward-word     # Ctrl+→
bindkey '^[[1;5D' backward-word    # Ctrl+←

# --- history -----------------------------------------------------------------
mkdir -p "$XDG_STATE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups \
       hist_save_no_dups hist_ignore_dups hist_find_no_dups

# --- aliases -----------------------------------------------------------------
alias ls='ls --color'
alias vim='nvim'
alias cat='bat'

# --- integrations (each only if installed) ------------------------------------
command -v fzf    >/dev/null && eval "$(fzf --zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

export NVM_DIR="$XDG_CONFIG_HOME/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# Angular CLI. Analytics off: otherwise its first run asks a yes/no question,
# which would hang shell startup (completion below runs `ng`).
export NG_CLI_ANALYTICS=false
# Completion script cached — running `ng` costs ~0.5 s of Node startup per
# shell. Regenerated when missing or older than the ng install.
if command -v ng >/dev/null; then
    _ng_comp="$XDG_CACHE_HOME/zsh/ng-completion.zsh"
    if [[ ! -s $_ng_comp || ${commands[ng]:A} -nt $_ng_comp ]]; then
        ng completion script >| "$_ng_comp" 2>/dev/null
    fi
    source "$_ng_comp"
    unset _ng_comp
fi

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# --- greeting ------------------------------------------------------------------
# fastfetch when a new kitty window/tab opens: kitty sets KITTY_WINDOW_ID, and
# SHLVL 1 = the shell kitty started (not a nested `zsh`, VS Code's terminal,
# or scripts).
if [[ -n $KITTY_WINDOW_ID && $SHLVL -eq 1 ]] && command -v fastfetch >/dev/null; then
    fastfetch
fi

# --- prompt (last) -------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"

# --- transient prompt ----------------------------------------------------------
# Starship's own `enable_transience` doesn't support zsh, so do it with a ZLE
# hook: when a line is accepted, redraw it with just "❯" (green/red by the last
# exit status, like the full prompt) before running it. Scrollback then shows
# one compact line per command; only the live prompt is the full powerline.
# (Starship only uses zle-keymap-select, so zle-line-init is free.)
_transient_prompt_line_init() {
    emulate -L zsh
    [[ $CONTEXT == start ]] || return 0
    while true; do
        zle .recursive-edit
        local -i ret=$?
        # Ctrl+D on an empty line: exit as usual
        [[ $ret == 0 && $KEYS == $'\4' ]] || break
        [[ -o ignore_eof ]] || exit 0
    done
    local saved_prompt=$PROMPT saved_rprompt=$RPROMPT
    PROMPT='$(starship module character --status="${STARSHIP_CMD_STATUS:-0}")'
    RPROMPT=''
    zle .reset-prompt
    PROMPT=$saved_prompt
    RPROMPT=$saved_rprompt
    if (( ret )); then zle .send-break; else zle .accept-line; fi
    return ret
}
command -v starship >/dev/null && zle -N zle-line-init _transient_prompt_line_init
