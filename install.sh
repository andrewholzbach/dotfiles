#!/usr/bin/env bash
#
# Bootstrap a machine from this dotfiles repo. Works on:
#   - macOS (Homebrew)
#   - Linux / DevPod containers (apt; other distros just get the symlinks)
#
# Safe to re-run, non-interactive on Linux, and backs up anything it replaces.
#
# macOS:   git clone <repo> ~/dotfiles && ~/dotfiles/install.sh
# DevPod:  devpod up <workspace> --dotfiles <repo-url>   (runs this automatically)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"
OS="$(uname -s)"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------- macOS ----------
install_macos() {
  if ! xcode-select -p >/dev/null 2>&1; then
    info "Installing Xcode Command Line Tools (a dialog will appear)..."
    xcode-select --install
    read -r -p "Press Enter once the installation has finished..."
  fi

  if ! have brew; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    else
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      else
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
  fi

  info "Installing packages from Brewfile..."
  brew bundle --file="$DOTFILES_DIR/Brewfile"
}

# ---------- Linux (DevPod containers, etc.) ----------
install_linux() {
  local SUDO=""
  if [[ $EUID -ne 0 ]]; then
    if have sudo; then SUDO="sudo"; else SUDO="none"; fi
  fi

  if have apt-get && [[ "$SUDO" != "none" ]]; then
    info "Installing packages with apt..."
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get update -y || warn "apt-get update failed"
    # Install individually so one missing package doesn't abort the rest
    for pkg in zsh git curl fzf ripgrep fd-find bat jq tree \
               zsh-autosuggestions zsh-syntax-highlighting; do
      $SUDO apt-get install -y --no-install-recommends "$pkg" \
        || warn "Could not install $pkg"
    done
  else
    warn "No apt-get or no root/sudo; skipping system packages."
  fi

  # Debian/Ubuntu install these under different names; add friendly aliases
  mkdir -p "$HOME/.local/bin"
  have fdfind && ! have fd  && ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  have batcat && ! have bat && ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"

  # Prompt and smarter cd via their official installers (no root needed)
  export PATH="$HOME/.local/bin:$PATH"
  if ! have starship && have curl; then
    info "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" \
      || warn "starship install failed"
  fi
  if ! have zoxide && have curl; then
    info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh \
      || warn "zoxide install failed"
  fi

  # Make zsh the login shell if we can
  if have zsh && [[ "${SHELL:-}" != *zsh ]]; then
    info "Setting zsh as the default shell..."
    if [[ "$SUDO" == "none" ]]; then
      warn "No root/sudo; can't change shell. Run 'zsh' manually."
    else
      $SUDO chsh -s "$(command -v zsh)" "$(id -un)" \
        || warn "chsh failed; run 'zsh' manually."
    fi
  fi
}

case "$OS" in
  Darwin) install_macos ;;
  Linux)  install_linux ;;
  *)      warn "Unsupported OS: $OS (only linking dotfiles)" ;;
esac

# ---------- Symlinks ----------
# Format: "path in repo|target path in $HOME"
LINKS=(
  "zsh/.zshrc|$HOME/.zshrc"
)

link_file() {
  local src="$1" dest="$2"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    info "Already linked: $dest"
    return
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    mkdir -p "$BACKUP_DIR"
    warn "Backing up existing $dest -> $BACKUP_DIR/"
    mv "$dest" "$BACKUP_DIR/"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  info "Linked $dest -> $src"
}

info "Linking dotfiles..."
for entry in "${LINKS[@]}"; do
  link_file "$DOTFILES_DIR/${entry%%|*}" "${entry##*|}"
done

# ---------- Local (untracked) overrides ----------
if [[ ! -f "$HOME/.zshrc.local" ]]; then
  cat > "$HOME/.zshrc.local" <<'LOCAL'
# Machine-specific settings and secrets. This file is NOT tracked in git.
# export SOME_API_KEY="..."
LOCAL
  info "Created ~/.zshrc.local"
fi

# ---------- Done ----------
if [[ "$OS" == "Darwin" ]]; then
  cat <<'MSG'

Done! A few manual iTerm steps:
  1. iTerm > Settings > Profiles > Text > Font: choose "MesloLGS Nerd Font"
  2. (Optional) Profiles > Keys > Key Mappings > Presets > "Natural Text Editing"
  3. Restart iTerm, or run: exec zsh
MSG
else
  info "Done! Start a new shell or run: exec zsh"
fi
