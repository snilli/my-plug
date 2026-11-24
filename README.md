# my-plug

snilli's Claude Code plugin. One plugin, `my-plug`, from the marketplace `snilli`:

| Part | What it does |
|---|---|
| Ghostty Stop notification (hook) | A native Ghostty desktop notification every time Claude finishes responding |
| `/my-plug:update-all` (skill) | Updates every plugin, skills CLI skill and the CLIs they call, then reports what changed |

## Install

```
/plugin marketplace add snilli/my-plug
/plugin install my-plug@snilli
```

Then **fully restart** Claude Code (quit and run `claude` fresh — not `--continue`)
so the plugin's hooks register. For local development, add the checkout instead:
`/plugin marketplace add /Users/snilli/Projects/hobby/my-plug`.

## Ghostty Stop notification

Fires a **native Ghostty desktop notification** on the `Stop` event. Because the
notification is delivered via an **OSC 9** escape sequence written to the terminal,
**Ghostty owns it** — so clicking the notification focuses the Ghostty tab, *not* Script Editor.

### Why

On macOS, notifications sent with `osascript -e 'display notification'` are owned by
Script Editor, so clicking one launches Script Editor. Tools that fall back to
`osascript` under non-iTerm2 terminals (e.g. ECC's `stop:desktop-notify`) hit this.
This hook uses the terminal-native OSC 9 path that Ghostty renders itself.

### Requirements

- macOS + [Ghostty](https://ghostty.org) (`TERM_PROGRAM=ghostty`)
- `jq` (for reading the transcript summary; optional — falls back to "Done")

### If you use ECC

ECC ships its own `stop:desktop-notify` hook that falls back to osascript under
Ghostty (→ Script Editor). Disable it so you don't get a duplicate, wrong-owner
notification. Add to `~/.claude/settings.json` (or export in your shell profile):

```json
"env": { "ECC_DISABLED_HOOKS": "stop:desktop-notify" }
```

### Behavior

- Fires on every `Stop`. No frontmost-suppression or dedup (yet).
- Body = first line of Claude's last message (truncated to 100 chars), else "Done".
- Skips silently when not under Ghostty, or inside tmux/screen (they swallow OSC 9).

## update-all

Updates everything a Claude Code setup depends on, in one run, and reports what changed.
Run `/my-plug:update-all`, or ask "update everything" (or "อัปเดต plugin ทุกตัว"). Or run the
script directly:

```
bash plugins/my-plug/scripts/update-all.sh [plugins|skills|tools|sources]
```

| Section | What it updates |
|---|---|
| plugins | every installed Claude Code plugin (`claude plugin marketplace update` + `claude plugin update`) |
| skills | skills installed with the `skills` CLI (`bunx skills update -g -y`) |
| tools | brew CLIs the skills call (`BREW_TOOLS`: rtk, jira-cli, bitbucket-cli, gh, uv, bun, aws-sam-cli, mysql-client, redis, ollama, jq), Claude Code (`BREW_CASKS`), global bun packages (`bun update -g --latest`), uv tools (`uv tool upgrade --all`) |

It deletes nothing: skills removed upstream are listed for you to remove. AnythingLLM and Ollama
models are not touched. MCP servers started with `bunx` update themselves when their config uses
`@latest` (for example `bunx cachebro@latest serve`); the script does not touch them.

## Layout

```
.claude-plugin/
  marketplace.json         # marketplace "snilli": lists the one plugin below
plugins/my-plug/
  .claude-plugin/plugin.json
  hooks/hooks.json         # Stop → hooks/ghostty-stop-notify.sh
  hooks/ghostty-stop-notify.sh
  skills/update-all/SKILL.md
  scripts/update-all.sh
  SOURCES.md               # snapshot of where every plugin/skill comes from
```
