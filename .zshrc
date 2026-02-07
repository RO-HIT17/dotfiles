# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
#fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git docker zsh-autosuggestions zsh-syntax-highlighting zsh-interactive-cd z)

source $ZSH/oh-my-zsh.sh

export PATH="$PATH:/home/rohit/.local/bin"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

eval "$(fnm env --use-on-cd)"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Enable globdots for completion
setopt globdots
_comp_options+=(globdots)

# FZF default commands - include hidden files with --hidden flag
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="fd --hidden --follow --exclude .git"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"

# FZF preview function - handles both files and directories with dotfiles
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always --all {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

# FZF preview options
export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --all {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)
      fzf --preview 'eza --tree --all --color=always {} | head -200' "$@" ;;
    export|unset)
      fzf --preview "eval 'echo ${}'" "$@" ;;
    ssh)
      fzf --preview 'dig {}' "$@" ;;
    *)
      fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# shellcheck disable=SC2034,SC2153,SC2086,SC2155
autoload -U add-zsh-hook
zmodload zsh/datetime 2>/dev/null

export ATUIN_SESSION=$(atuin uuid)
ATUIN_HISTORY_ID=""

# Atuin strategy for zsh-autosuggestions
_zsh_autosuggest_strategy_atuin() {
    suggestion=$(ATUIN_QUERY="$1" atuin search --cmd-only --limit 1 --search-mode prefix 2>/dev/null)
}

if [ -n "${ZSH_AUTOSUGGEST_STRATEGY:-}" ]; then
    ZSH_AUTOSUGGEST_STRATEGY=("atuin" "${ZSH_AUTOSUGGEST_STRATEGY[@]}")
else
    ZSH_AUTOSUGGEST_STRATEGY=("atuin")
fi

_atuin_preexec() {
    local id
    id=$(atuin history start -- "$1")
    export ATUIN_HISTORY_ID="$id"
    __atuin_preexec_time=${EPOCHREALTIME-}
}

_atuin_precmd() {
    local EXIT="$?" __atuin_precmd_time=${EPOCHREALTIME-}

    [[ -z "${ATUIN_HISTORY_ID:-}" ]] && return

    local duration=""
    if [[ -n $__atuin_preexec_time && -n $__atuin_precmd_time ]]; then
        printf -v duration %.0f $(((__atuin_precmd_time - __atuin_preexec_time) * 1000000000))
    fi

    (ATUIN_LOG=error atuin history end --exit $EXIT ${duration:+--duration=$duration} -- $ATUIN_HISTORY_ID &) >/dev/null 2>&1
    export ATUIN_HISTORY_ID=""
}

_atuin_search() {
    emulate -L zsh
    zle -I

    local output
    # shellcheck disable=SC2048
    output=$(ATUIN_SHELL=zsh ATUIN_LOG=error ATUIN_QUERY=$BUFFER atuin search $* -i 3>&1 1>&2 2>&3)

    zle reset-prompt
    # shellcheck disable=SC2154
    echo -n ${zle_bracketed_paste[1]} >/dev/tty

    if [[ -n $output ]]; then
        RBUFFER=""
        LBUFFER=$output

        if [[ $LBUFFER == __atuin_accept__:* ]]
        then
            LBUFFER=${LBUFFER#__atuin_accept__:}
            zle accept-line
        fi
    fi
}

_atuin_search_vicmd() {
    _atuin_search --keymap-mode=vim-normal
}

_atuin_search_viins() {
    _atuin_search --keymap-mode=vim-insert
}

_atuin_up_search() {
    if [[ ! $BUFFER == *$'\n'* ]]; then
        _atuin_search --shell-up-key-binding "$@"
    else
        zle up-line
    fi
}

_atuin_up_search_vicmd() {
    _atuin_up_search --keymap-mode=vim-normal
}

_atuin_up_search_viins() {
    _atuin_up_search --keymap-mode=vim-insert
}

add-zsh-hook preexec _atuin_preexec
add-zsh-hook precmd _atuin_precmd

# Atuin widgets
zle -N atuin-search _atuin_search
zle -N atuin-search-vicmd _atuin_search_vicmd
zle -N atuin-search-viins _atuin_search_viins
zle -N atuin-up-search _atuin_up_search
zle -N atuin-up-search-vicmd _atuin_up_search_vicmd
zle -N atuin-up-search-viins _atuin_up_search_viins
zle -N _atuin_search_widget _atuin_search
zle -N _atuin_up_search_widget _atuin_up_search

# FZF custom directory widget
fzf-cd-widget() {
  local dir
  dir=$(fd --type d --hidden --follow --exclude .git . | fzf \
    --preview 'eza --tree --color=always --all {} | head -200')
  [[ -n "$dir" ]] && cd "$dir"
  zle reset-prompt
}
zle -N fzf-cd-widget

# Atuin bindings
bindkey -M emacs '^r' atuin-search
bindkey -M viins '^r' atuin-search-viins
bindkey -M vicmd '/' atuin-search
bindkey -M emacs '^[[A' atuin-up-search
bindkey -M vicmd '^[[A' atuin-up-search-vicmd
bindkey -M viins '^[[A' atuin-up-search-viins
bindkey -M emacs '^[OA' atuin-up-search
bindkey -M vicmd '^[OA' atuin-up-search-vicmd
bindkey -M viins '^[OA' atuin-up-search-viins
bindkey -M vicmd 'k' atuin-up-search-vicmd

# FZF bindings
bindkey '^G' fzf-cd-widget


# Menu select bindings (hjkl navigation)
bindkey -M menuselect 'h' backward-char
bindkey -M menuselect 'l' forward-char
bindkey -M menuselect 'j' down-line-or-history
bindkey -M menuselect 'k' up-line-or-history

zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ============================================================================
# ALIASES
# ============================================================================
alias ls="eza --long --icons=always --no-filesize --no-user --no-time --no-permissions --color=always --all"

eval $(thefuck --alias)
eval $(thefuck --alias fk)
