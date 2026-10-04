# ~/.zshrc -- managed in ~/dotfiles

# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# PATH and environment
typeset -U path
path=("$HOME/.local/bin" "$HOME/bin" $path)
export EDITOR="${EDITOR:-vim}"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-FRX"
export CLICOLOR=1
export LANG="${LANG:-en_US.UTF-8}"

# Shell behavior
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt CORRECT

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# Completion
if command -v brew >/dev/null 2>&1; then
  FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
fi

autoload -Uz compinit
() {
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
  else
    compinit -C
  fi
}
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Key bindings
bindkey -e
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^[[3~' delete-char

# Aliases
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias mkdir='mkdir -p'
alias reload='exec zsh'
alias path='echo $PATH | tr ":" "\n"'

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --git --group-directories-first'
  alias tree='eza --tree'
else
  if [[ "$OSTYPE" == darwin* ]]; then
    alias ls='ls -G'
  else
    alias ls='ls --color=auto'
  fi
  alias ll='ls -lah'
fi
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'

# Git
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gp='git push'

# macOS helpers
if [[ "$OSTYPE" == darwin* ]]; then
  alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
  alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'
  alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
fi

# Functions
mkcd() { mkdir -p "$1" && cd "$1"; }

extract() {
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.zip)            unzip "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.7z)             7z x "$1" ;;
    *) echo "extract: don't know how to extract '$1'" >&2; return 1 ;;
  esac
}

# Tool integrations
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/doc/fzf/examples/completion.zsh; do
      [[ -f "$f" ]] && source "$f"
    done
  fi
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# Prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  PROMPT='%F{cyan}%~%f %F{green}❯%f '
fi

# Plugins
plugin_dirs=(/usr/share)
command -v brew >/dev/null 2>&1 && plugin_dirs=("$(brew --prefix)/share" $plugin_dirs)

for d in $plugin_dirs; do
  [[ -f "$d/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
    { source "$d/zsh-autosuggestions/zsh-autosuggestions.zsh"; break; }
done

for d in $plugin_dirs; do
  [[ -f "$d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
    { source "$d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; break; }
done
unset plugin_dirs d

# Machine-local overrides
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
