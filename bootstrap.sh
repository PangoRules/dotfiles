#!/usr/bin/env bash
# =============================================================================
# Dotfiles Bootstrap Script
# =============================================================================
# Idempotent setup script for a fresh machine. Safe to run multiple times.
# Usage: bash bootstrap.sh [--skip-tools] [--skip-nvim] [--skip-vscode]
# =============================================================================

set -euo pipefail

# --- Flags -------------------------------------------------------------------
SKIP_TOOLS=false
SKIP_NVIM=false
SKIP_VSCODE=false

for arg in "$@"; do
  case "$arg" in
    --skip-tools)  SKIP_TOOLS=true ;;
    --skip-nvim)   SKIP_NVIM=true ;;
    --skip-vscode) SKIP_VSCODE=true ;;
  esac
done

# --- Helpers -----------------------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

header() { echo -e "\n${BOLD}${CYAN}=== $1 ===${RESET}"; }
ok()     { echo -e "  ${GREEN}✓${RESET} $1"; }
skip()   { echo -e "  ${YELLOW}→${RESET} $1 (already done, skipping)"; }
info()   { echo -e "  ${CYAN}•${RESET} $1"; }
warn()   { echo -e "  ${YELLOW}⚠${RESET} $1"; }
err()    { echo -e "  ${RED}✗${RESET} $1"; }

# Backup a file if it exists and is not already a symlink
backup_if_exists() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mv "$target" "${target}.bak"
    warn "Backed up existing $(basename "$target") → ${target}.bak"
  fi
}

# Create a symlink, backing up any existing file first
make_symlink() {
  local src="$1"   # file in dotfiles repo (absolute)
  local dst="$2"   # destination in home dir

  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    skip "$dst already symlinked"
    return
  fi

  backup_if_exists "$dst"
  ln -sf "$src" "$dst"
  ok "Linked $dst → $src"
}

# =============================================================================
# 1. SYSTEM TOOLS
# =============================================================================
if [[ "$SKIP_TOOLS" == false ]]; then
  header "1. System Tools"

  # Prerequisites
  for cmd in git zsh curl; do
    if ! command -v "$cmd" &>/dev/null; then
      err "$cmd is required but not installed. Install it first and re-run."
      exit 1
    fi
  done
  ok "Prerequisites: git, zsh, curl"

  # Oh-My-Zsh
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    skip "Oh-My-Zsh"
  else
    info "Installing Oh-My-Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Oh-My-Zsh installed"
  fi

  # Powerlevel10k
  P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ -d "$P10K_DIR" ]]; then
    skip "Powerlevel10k theme"
  else
    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    ok "Powerlevel10k installed"
  fi

  # zsh-autosuggestions
  ZSH_AUTO_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [[ -d "$ZSH_AUTO_DIR" ]]; then
    skip "zsh-autosuggestions plugin"
  else
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTO_DIR"
    ok "zsh-autosuggestions installed"
  fi

  # zsh-syntax-highlighting
  ZSH_SYNTAX_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [[ -d "$ZSH_SYNTAX_DIR" ]]; then
    skip "zsh-syntax-highlighting plugin"
  else
    info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_DIR"
    ok "zsh-syntax-highlighting installed"
  fi

  # Volta (Node.js version manager)
  if command -v volta &>/dev/null; then
    skip "Volta"
  else
    info "Installing Volta..."
    curl https://get.volta.sh | bash
    ok "Volta installed"
  fi

  # uv (Python package manager)
  if command -v uv &>/dev/null; then
    skip "uv"
  else
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ok "uv installed"
  fi

else
  header "1. System Tools"
  info "Skipped (--skip-tools)"
fi

# =============================================================================
# 2. NEOVIM CONFIG
# =============================================================================
if [[ "$SKIP_NVIM" == false ]]; then
  header "2. Neovim Config"

  NVIM_CONFIG_DIR="$HOME/.config/nvim"
  if [[ -d "$NVIM_CONFIG_DIR/.git" ]]; then
    skip "~/.config/nvim (already cloned)"
  else
    if [[ -d "$NVIM_CONFIG_DIR" ]]; then
      warn "~/.config/nvim exists but is not a git repo — backing up..."
      mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.bak"
      warn "Backed up to ~/.config/nvim.bak"
    fi
    info "Cloning nvim config..."
    git clone git@github.com:PangoRules/nvim-config.git "$NVIM_CONFIG_DIR"
    ok "Neovim config cloned to ~/.config/nvim"
  fi

else
  header "2. Neovim Config"
  info "Skipped (--skip-nvim)"
fi

# =============================================================================
# 3. SYMLINKS
# =============================================================================
header "3. Creating Symlinks"

make_symlink "$DOTFILES_DIR/shell/.zshrc"    "$HOME/.zshrc"
make_symlink "$DOTFILES_DIR/shell/.p10k.zsh" "$HOME/.p10k.zsh"
make_symlink "$DOTFILES_DIR/git/.gitconfig"  "$HOME/.gitconfig"
make_symlink "$DOTFILES_DIR/git/ignore"      "$HOME/.config/git/ignore"
make_symlink "$DOTFILES_DIR/npm/.npmrc"      "$HOME/.npmrc"
make_symlink "$DOTFILES_DIR/nuxt/.nuxtrc"    "$HOME/.nuxtrc"
make_symlink "$DOTFILES_DIR/env/99-nvidia-vulkan.conf" \
             "$HOME/.config/environment.d/99-nvidia-vulkan.conf"

# =============================================================================
# 4. VS CODE SETUP (optional — skipped if `code` is not installed)
# =============================================================================
if [[ "$SKIP_VSCODE" == false ]]; then
  header "4. VS Code Setup"

  if ! command -v code &>/dev/null; then
    warn "VS Code (code) not found — skipping VS Code setup"
  else
    # Settings: copy (not symlink — VS Code rewrites this file)
    VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"
    VSCODE_SETTINGS_SRC="$DOTFILES_DIR/vscode/settings.json"
    VSCODE_SETTINGS_DST="$VSCODE_SETTINGS_DIR/settings.json"
    mkdir -p "$VSCODE_SETTINGS_DIR"

    if [[ -f "$VSCODE_SETTINGS_DST" ]]; then
      skip "VS Code settings.json (already exists — remove to re-apply)"
    else
      cp "$VSCODE_SETTINGS_SRC" "$VSCODE_SETTINGS_DST"
      ok "Copied VS Code settings.json"
    fi

    # Extensions
    EXTENSIONS_FILE="$DOTFILES_DIR/vscode/extensions.txt"
    if [[ -f "$EXTENSIONS_FILE" ]]; then
      info "Installing VS Code extensions from extensions.txt..."
      while IFS= read -r ext; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        if code --list-extensions 2>/dev/null | grep -qi "^${ext}$"; then
          skip "Extension $ext"
        else
          code --install-extension "$ext" --force &>/dev/null && ok "Installed $ext" || warn "Failed to install $ext"
        fi
      done < "$EXTENSIONS_FILE"
    else
      warn "extensions.txt not found — skipping extension installs"
    fi
  fi

else
  header "4. VS Code Setup"
  info "Skipped (--skip-vscode)"
fi

# =============================================================================
# 5. POST-INSTALL REMINDERS
# =============================================================================
header "5. Post-Install Reminders"

echo -e "
  ${BOLD}Things to do manually:${RESET}

  1. ${YELLOW}SSH keys${RESET}
     Generate a new key or copy your existing key:
       ssh-keygen -t ed25519 -C \"your@email.com\"
     Then add it to GitHub: https://github.com/settings/keys

  2. ${YELLOW}Node.js via Volta${RESET}
     Volta was installed but no Node version is pinned globally yet.
     Run: volta install node

  3. ${YELLOW}Claude Code${RESET}
     Authenticate after installing:
       claude auth login

  4. ${YELLOW}Powerlevel10k${RESET}
     If the prompt looks wrong, re-run the config wizard:
       p10k configure

  5. ${YELLOW}NVIDIA Vulkan env var${RESET}
     99-nvidia-vulkan.conf was symlinked. Only applies if you have an NVIDIA GPU.
     Reboot (or re-login) for environment.d changes to take effect.

  6. ${YELLOW}Neovim plugins${RESET}
     Open nvim and run: :Lazy sync
"

echo -e "${BOLD}${GREEN}Bootstrap complete!${RESET}"
