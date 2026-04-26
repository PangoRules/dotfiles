# opencode config

Global opencode configuration, agents, and commands — tracked in dotfiles so any machine gets the same setup.

## What's here

| Path | Purpose |
|------|---------|
| `opencode.json` | Base config: schema + superpowers plugin |
| `agents/caveman.md` | Caveman coder agent — implements plans exactly, no fluff |
| `agents/prompt-optimizer.md` | Prompt optimizer agent — invoked via `/prompt` command |
| `commands/prompt.md` | `/prompt <text>` — optimizes a prompt using Claude's best practices |

## Symlinks (managed by bootstrap.sh)

```
~/.config/opencode/opencode.json  →  ~/dotfiles/opencode/opencode.json
~/.config/opencode/agents         →  ~/dotfiles/opencode/agents/
~/.config/opencode/commands       →  ~/dotfiles/opencode/commands/
```

## Per-machine configuration

`opencode.json` only includes the superpowers plugin. You need to add your local provider and model after pulling on a new machine.

### Ollama (local)

Add to `~/.config/opencode/opencode.json` — but since that file is a symlink to dotfiles, create a local override instead by editing it directly OR add the provider config as a local layer. The simplest approach: temporarily unlink, edit, re-link.

Actually the easiest flow on a new machine:
1. Run `bash ~/dotfiles/bootstrap.sh` — symlinks are created
2. Open `~/dotfiles/opencode/opencode.json` and append your provider locally (don't commit it)
3. OR: break the symlink and keep a machine-local copy: `cp --remove-destination $(readlink ~/.config/opencode/opencode.json) ~/.config/opencode/opencode.json`

### Example provider blocks

**Ollama:**
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen3-coder:latest",
  "small_model": "ollama/gemma4:latest",
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"],
  "provider": {
    "ollama": {
      "name": "Ollama",
      "npm": "@ai-sdk/openai-compatible",
      "options": { "baseURL": "http://127.0.0.1:11434/v1" },
      "models": {
        "gemma4:latest":       { "name": "gemma4:latest" },
        "qwen3-coder:latest":  { "name": "qwen3-coder:latest" }
      }
    }
  }
}
```

**Anthropic (cloud):**
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```
Set `ANTHROPIC_API_KEY` in your environment or run `/connect` inside opencode.

## Adding new agents or commands

Add files to `agents/` or `commands/` in this repo and commit. They'll be available on every machine that uses these dotfiles.
