# Dotfiles

Personal development environment configuration for Rafael Bolaños.

## What's Included

| Directory | File | Maps To |
|-----------|------|---------|
| `shell/` | `.zshrc` | `~/.zshrc` |
| `shell/` | `.p10k.zsh` | `~/.p10k.zsh` |
| `git/` | `.gitconfig` | `~/.gitconfig` |
| `git/` | `ignore` | `~/.config/git/ignore` |
| `npm/` | `.npmrc` | `~/.npmrc` |
| `nuxt/` | `.nuxtrc` | `~/.nuxtrc` |
| `env/` | `99-nvidia-vulkan.conf` | `~/.config/environment.d/99-nvidia-vulkan.conf` |
| `vscode/` | `settings.json` | `~/.config/Code/User/settings.json` (copied) |
| `vscode/` | `extensions.txt` | installed via `code --install-extension` |

**Not managed here:**
- `~/.config/nvim/` — cloned from `git@github.com:PangoRules/nvim-config.git`
- `~/.ssh/` — never commit keys
- `~/.claude/` — machine-specific runtime state

## Bootstrap a New Machine

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
bash bootstrap.sh
```

The script is **idempotent** — safe to run multiple times. Each step is skipped if already done.

### Options

```bash
bash bootstrap.sh --skip-tools    # skip tool installs (Oh-My-Zsh, Volta, uv, etc.)
bash bootstrap.sh --skip-nvim     # skip neovim config clone
bash bootstrap.sh --skip-vscode   # skip VS Code settings + extension installs
```

### What bootstrap.sh does

1. **System tools** — Checks prerequisites (git, zsh, curl), installs Oh-My-Zsh, Powerlevel10k theme, zsh-autosuggestions, zsh-syntax-highlighting, Volta, and uv
2. **Neovim config** — Clones `nvim-config` repo to `~/.config/nvim`
3. **Symlinks** — Links all dotfiles from this repo into their expected home directory locations
4. **VS Code** — Copies `settings.json` and installs all extensions from `extensions.txt`
5. **Reminders** — Prints a checklist of manual steps (SSH keys, `volta install node`, etc.)

## Verification

After running on a fresh machine:

```bash
# Symlinks should point into ~/dotfiles/
ls -la ~/.zshrc ~/.p10k.zsh ~/.gitconfig ~/.npmrc ~/.nuxtrc

# Open a new terminal — Powerlevel10k prompt should appear
# Git should show your identity
git log  # should show "Rafael Bolaños"

# Neovim — launch and sync plugins
nvim  # then :Lazy sync

# Node
volta install node
node --version

# VS Code
code  # Catppuccin Mocha theme, all extensions installed
```

## Updating

When you change a config file (e.g., add a new alias to `.zshrc`), the change is
immediately reflected in the dotfiles repo because the home directory files are symlinks.
Just commit and push:

```bash
cd ~/dotfiles
git add shell/.zshrc
git commit -m "Add new alias"
git push
```

For VS Code, the settings file is **copied** (not symlinked) because VS Code rewrites
it directly. To update:

```bash
cp ~/.config/Code/User/settings.json ~/dotfiles/vscode/settings.json
code --list-extensions > ~/dotfiles/vscode/extensions.txt
cd ~/dotfiles && git add vscode/ && git commit -m "Update VS Code config"
```
