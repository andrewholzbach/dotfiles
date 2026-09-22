# ~/.zshrc -- managed in ~/dotfiles
# This file runs every time you open a new interactive shell (a new tab,
# a new window, or `exec zsh`). It does NOT run for non-interactive shells
# (like scripts run via `zsh script.sh`), so aliases/prompt stuff here is safe.

# ============================================================
# Homebrew
# ============================================================
# `brew shellenv` prints export statements that put Homebrew's bin dirs on
# PATH, plus a few other env vars (MANPATH, etc). We eval it so those take
# effect in this shell. Two paths because Apple Silicon and Intel Macs
# install Homebrew to different locations.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon (M1/M2/M3...) Macs
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"      # Intel Macs
fi
# On Linux (e.g. DevPod) neither path exists, so this block is a no-op there.

# ============================================================
# PATH
# ============================================================
# `typeset -U path` tells zsh to keep the `path` array unique: if something
# gets added twice, only the first copy is kept. This is zsh-specific magic:
# the special array `path` and the env var `$PATH` are "tied together", so
# changing one changes the other automatically.
typeset -U path
# Prepend your personal bin directories so anything you put there overrides
# system versions of the same command name.
path=("$HOME/.local/bin" "$HOME/bin" $path)

# ============================================================
# Environment variables
# ============================================================
# EDITOR/VISUAL: which text editor opens for things like `git commit`,
# `crontab -e`, etc. `${EDITOR:-vim}` means "use $EDITOR if already set
# (e.g. by .zshrc.local), otherwise default to vim".
export EDITOR="${EDITOR:-vim}"
export VISUAL="$EDITOR"          # some programs check VISUAL instead of EDITOR
export PAGER="less"              # program used to page through long output
export LESS="-FRX"               # less options: F=quit if content fits one screen,
                                  # R=show color codes properly, X=don't clear
                                  # the screen on exit (so output stays visible)
export CLICOLOR=1                # tells BSD/macOS `ls` to use colors
export LANG="${LANG:-en_US.UTF-8}"   # locale (affects sorting, character encoding)

# ============================================================
# Shell options (setopt)
# ============================================================
# Full reference: run `man zshoptions` or see http://zsh.sourceforge.net/Doc/Release/Options.html
setopt AUTO_CD              # typing a bare directory name (e.g. `Downloads`) cd's into it,
                             # instead of needing `cd Downloads`
setopt AUTO_PUSHD           # every `cd` also pushes the old directory onto a stack;
                             # see the directory stack, use `dirs -v`, jump back with `cd -2`
setopt PUSHD_IGNORE_DUPS    # don't push a directory onto the stack if it's already there
setopt INTERACTIVE_COMMENTS # lets you type/paste a line starting with `#` at the prompt
                             # without zsh trying to execute it as a command
setopt NO_BEEP               # disable the terminal bell on errors (e.g. bad Tab completion)
setopt CORRECT              # zsh will ask "correct 'gti' to 'git'? [Yn]" on typos.
                             # NOTE: some people find this intrusive - delete this line
                             # if a misspelled command name should just fail normally.

# ============================================================
# History
# ============================================================
HISTFILE="$HOME/.zsh_history"   # where history is saved to disk
HISTSIZE=50000                  # how many lines to keep in memory during a session
SAVEHIST=50000                  # how many lines to keep in the HISTFILE on disk
setopt EXTENDED_HISTORY       # save a timestamp + duration with each history entry
setopt INC_APPEND_HISTORY     # write each command to HISTFILE as soon as it runs,
                               # instead of only when the shell exits (so history
                               # isn't lost if a tab crashes, and other tabs see it sooner)
setopt SHARE_HISTORY          # continually import new history from HISTFILE, and share
                               # it live across all open tabs/windows (implies some of
                               # INC_APPEND_HISTORY's behavior, but both are kept here
                               # for clarity/compatibility)
setopt HIST_IGNORE_ALL_DUPS   # if you run the same command again, delete the OLDER
                               # copy from history so you don't get clutter of repeats
setopt HIST_IGNORE_SPACE      # a command typed with a LEADING SPACE is not saved to
                               # history at all - useful for one-off commands containing
                               # a password or token you don't want recorded
setopt HIST_REDUCE_BLANKS     # trim extra whitespace within a history entry before saving
setopt HIST_VERIFY            # when you recall a history expansion like `!!` or `!42`,
                               # show the expanded command on the prompt line first
                               # instead of immediately running it - lets you check it

# ============================================================
# Completion (Tab-completion system)
# ============================================================
# FPATH is where zsh looks for completion definition files. zsh-completions
# (a Homebrew package) ships extra definitions for tools that don't bundle
# their own. This must be set BEFORE `compinit` runs below.
if command -v brew >/dev/null 2>&1; then
  FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
fi

# `compinit` is the function that actually activates the completion system.
# It's somewhat slow because it scans all of FPATH for completion definitions
# and rebuilds a cache file (~/.zcompdump). We only want to pay that cost
# once a day, not on every new tab.
autoload -Uz compinit
# Only regenerate the completion dump once a day (faster startup).
# The `(#qN.mh+24)` glob qualifier means "match files modified more than
# 24 hours ago"; it requires the EXTENDED_GLOB option, which we don't want
# enabled shell-wide, so it's scoped to this one anonymous function `() { ... }`
# via `setopt LOCAL_OPTIONS` (LOCAL_OPTIONS makes any setopt inside this
# function revert automatically when the function returns).
() {
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit           # dump is missing or stale (>24h old): do a full rebuild
  else
    compinit -C        # dump is fresh: skip the safety checks and load it as-is (faster)
  fi
}

# zstyle configures behavior of the completion system (":completion:*" means
# "apply to all completion contexts").
zstyle ':completion:*' menu select
  # ^ after pressing Tab once shows a list, pressing Tab again lets you
  #   arrow through it and select with Enter, instead of just cycling blindly
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
  # ^ makes completion case-insensitive, e.g. typing `dow<Tab>` can match `Downloads`
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  # ^ colorize completion listings (files/dirs) using the same colors as `ls`

# ============================================================
# Key bindings (iTerm-friendly)
# ============================================================
bindkey -e
  # ^ Use emacs-style line editing (Ctrl+A = start of line, Ctrl+E = end,
  #   Ctrl+W = delete word, etc). This matters because if $EDITOR contains
  #   "vi" (ours is set to vim above), zsh silently switches to vi-mode
  #   keybindings by default - this line forces emacs-style regardless.
bindkey '^[[1;3D' backward-word              # Option+Left: jump back one word
bindkey '^[[1;3C' forward-word               # Option+Right: jump forward one word
bindkey '^[b' backward-word                  # same as above, alternate escape
                                              # sequence some terminal configs send
bindkey '^[f' forward-word                   # same as above, alternate escape sequence
bindkey '^[[A' history-beginning-search-backward
  # ^ Up arrow: search history backward, but only show entries that start
  #   with whatever you've already typed on the line (a "prefix search").
  #   E.g. type `git ` then press Up to cycle only through past `git` commands.
bindkey '^[[B' history-beginning-search-forward   # Down arrow: same, but forward
bindkey '^[[3~' delete-char                  # makes the Fn+Delete / forward-delete key work
# Note: these escape sequences (^[[1;3D etc.) are what iTerm sends for
# Option+Arrow by default. If Option+Arrow doesn't work for you, go to
# iTerm > Settings > Profiles > Keys > "Key Mappings" and apply the
# "Natural Text Editing" preset, which sends these same sequences.

# ============================================================
# Aliases
# ============================================================
# Quick directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'          # `-` alone returns to the previous directory
                            # (the `--` tells alias "the next word is the alias
                            # name, not an option", since `-` looks like a flag)

# Safer/nicer defaults for common commands
alias grep='grep --color=auto'   # highlight matches in grep output
alias df='df -h'                 # disk free, human-readable sizes (GB/MB not bytes)
alias du='du -h'                 # disk usage, human-readable sizes
alias mkdir='mkdir -p'           # -p creates parent dirs as needed & doesn't
                                  # error if the dir already exists
alias reload='exec zsh'          # restart your shell in-place, picking up .zshrc changes
alias path='echo $PATH | tr ":" "\n"'   # print PATH one entry per line (easier to read)

# Prefer modern tools when they're installed, otherwise fall back to
# the classic command with sane flags.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'         # eza: a modern `ls` replacement
                                                     # (colors, icons, git status)
  alias ll='eza -lah --git --group-directories-first'  # long listing incl. hidden files,
                                                          # with git status column
  alias tree='eza --tree'                            # eza can also do tree view
else
  # BSD `ls` (macOS default) uses -G for color; GNU `ls` (Linux) uses --color
  if [[ "$OSTYPE" == darwin* ]]; then alias ls='ls -G'; else alias ls='ls --color=auto'; fi
  alias ll='ls -lah'    # -l long format, -a show hidden files, -h human-readable sizes
fi
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
  # ^ bat: a `cat` replacement with syntax highlighting and line numbers.
  #   --paging=never keeps it behaving like plain `cat` (no `less`-style pager)
  #   so it doesn't surprise you in scripts or pipes.

# Git shortcuts - short aliases for commands you'll type constantly
alias g='git'
alias gs='git status -sb'                            # -s short format, -b show branch
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'  # compact, visual log of last 20 commits
alias gp='git push'

# macOS-only helpers (guarded so this block does nothing on Linux)
if [[ "$OSTYPE" == darwin* ]]; then
  alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
    # ^ makes Finder show hidden dotfiles; killall restarts Finder to apply it
  alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'
  alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
    # ^ clears macOS's DNS cache - handy when a domain isn't resolving as expected
fi

# ============================================================
# Functions
# ============================================================
# Functions can do things aliases can't, like take arguments and run
# multiple commands conditionally.

mkcd() { mkdir -p "$1" && cd "$1"; }
  # ^ usage: `mkcd myproject` creates the directory AND cd's into it in one step

extract() {
  # usage: `extract somefile.tar.gz` - detects the archive type from the
  # extension and runs the right extraction command, so you don't have to
  # remember `tar xzf` vs `tar xjf` vs `unzip` etc.
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

# ============================================================
# Tool integrations (each block is a no-op if the tool isn't installed,
# so this file works even before you've installed everything)
# ============================================================

# fzf - general-purpose fuzzy finder. Once loaded it adds:
#   Ctrl+R  -> fuzzy-search your command history
#   Ctrl+T  -> fuzzy-find a file/dir and insert its path at the cursor
#   Alt+C   -> fuzzy-find a directory and cd into it
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)   # modern fzf (0.48+) has this built-in integration flag
  else
    # Older fzf, e.g. installed via `apt install fzf` on Debian/Ubuntu, doesn't
    # support `--zsh` and instead ships separate shell script files - load
    # those directly if we find them.
    for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/doc/fzf/examples/completion.zsh; do
      [[ -f "$f" ]] && source "$f"
    done
  fi
  if command -v fd >/dev/null 2>&1; then
    # Tell fzf to use `fd` instead of the default `find` for Ctrl+T/file
    # listing - fd is faster and respects .gitignore automatically.
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    # ^ open fzf as a 40%-height panel at the bottom (not fullscreen), with
    #   the prompt at the top ("reverse" layout) and a border around it
fi

# zoxide - a smarter `cd` that learns your habits. After using it for a
# while, `z proj` jumps straight to your most-visited directory matching
# "proj", even if it's several levels deep - no need to type the full path.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# direnv - loads/unloads environment variables automatically when you cd
# into (or out of) a directory containing a `.envrc` file. Useful for
# per-project env vars (API keys, tool versions) without polluting your
# global shell. You must run `direnv allow` once per .envrc to approve it
# (a security measure, since .envrc can run arbitrary shell code).
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# ============================================================
# Prompt
# ============================================================
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
    # ^ starship: a customizable prompt that shows things like current git
    #   branch/status, language runtime versions (node, python, etc) when
    #   relevant, and command duration. Configured via ~/.config/starship.toml
    #   (not created yet). Needs a Nerd Font in your terminal to show icons
    #   correctly instead of boxes/question marks.
else
  # Fallback prompt if starship isn't installed: shows current directory in
  # cyan, then a green ❯ as the prompt character.
  PROMPT='%F{cyan}%~%f %F{green}❯%f '
fi

# ============================================================
# Plugins (Homebrew on macOS, apt on Linux)
# ============================================================
# Build a list of directories to search for plugin files, since Homebrew
# and apt install them to different locations.
plugin_dirs=(/usr/share)
command -v brew >/dev/null 2>&1 && plugin_dirs=("$(brew --prefix)/share" $plugin_dirs)

# zsh-autosuggestions: as you type, shows a greyed-out suggestion completing
# your command based on your history. Press -> (right arrow) or End to
# accept the suggestion.
for d in $plugin_dirs; do
  [[ -f "$d/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
    { source "$d/zsh-autosuggestions/zsh-autosuggestions.zsh"; break; }
done

# zsh-syntax-highlighting: colors the command you're typing in real time -
# green if it's a valid/known command, red if it isn't, etc. This MUST be
# sourced after everything else (aliases, other plugins) or its highlighting
# breaks, which is why this block is last.
for d in $plugin_dirs; do
  [[ -f "$d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
    { source "$d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; break; }
done
unset plugin_dirs d   # clean up helper variables so they don't linger in your shell

# ============================================================
# Machine-local overrides (NOT tracked in git - see .gitignore)
# ============================================================
# Put secrets (API keys, tokens), work-specific aliases, or per-machine
# PATH tweaks in ~/.zshrc.local. It's sourced last so it can override
# anything above. install.sh creates an empty stub for you automatically.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
