# ~/.zshenv — read by every zsh (login, interactive, scripts). Keep it tiny:
# point zsh at ~/.config/zsh so .zshrc lives in the repo (config/zsh/.zshrc).
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export EDITOR=nvim
export VISUAL=nvim
