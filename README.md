# ghostty-stop-notify

A Claude Code plugin that fires a **native Ghostty desktop notification** every time
Claude finishes responding (the `Stop` event). Because the notification is delivered
via an **OSC 9** escape sequence written to the terminal, **Ghostty owns it** — so
clicking the notification focuses the Ghostty tab, *not* Script Editor.

## Why

On macOS, notifications sent with `osascript -e 'display notification'` are owned by
Script Editor, so clicking one launches Script Editor. Tools that fall back to
`osascript` under non-iTerm2 terminals (e.g. ECC's `stop:desktop-notify`) hit this.
This plugin uses the terminal-native OSC 9 path that Ghostty renders itself.

## Requirements

- macOS + [Ghostty](https://ghostty.org) (`TERM_PROGRAM=ghostty`)
- `jq` (for reading the transcript summary; optional — falls back to "Done")

## Install

```
/plugin marketplace add /Users/snilli/Projects/hobby/my-plug
/plugin install ghostty-stop-notify@my-plug
```

Then **fully restart** Claude Code (quit and run `claude` fresh — not `--continue`)
so the plugin's hooks register.

Moving to a new machine: push this repo to git, then on the other machine
`/plugin marketplace add <git-url>` + `/plugin install ghostty-stop-notify@my-plug`.

## If you use ECC

ECC ships its own `stop:desktop-notify` hook that falls back to osascript under
Ghostty (→ Script Editor). Disable it so you don't get a duplicate, wrong-owner
notification. Add to `~/.claude/settings.json` (or export in your shell profile):

```json
"env": { "ECC_DISABLED_HOOKS": "stop:desktop-notify" }
```

## Behavior

- Fires on every `Stop`. No frontmost-suppression or dedup (yet).
- Body = first line of Claude's last message (truncated to 100 chars), else "Done".
- Skips silently when not under Ghostty, or inside tmux/screen (they swallow OSC 9).

## Layout

```
.claude-plugin/
  plugin.json        # manifest + inline Stop hook
  marketplace.json   # lets `/plugin marketplace add <path>` find it
hooks/
  ghostty-stop-notify.sh
plugins/update-all/  # second plugin, see below
```

# update-all

A skill that updates everything a Claude Code setup depends on, in one run, and reports what
changed. Install with `/plugin install update-all@my-plug`, then ask "update everything"
(or "อัปเดต plugin ทุกตัว"). Or run the script directly:

```
bash plugins/update-all/scripts/update-all.sh [plugins|skills|tools]
```

| Section | What it updates |
|---|---|
| plugins | every installed Claude Code plugin (`claude plugin marketplace update` + `claude plugin update`) |
| skills | skills installed with the `skills` CLI (`bunx skills update -g -y`) |
| tools | brew CLIs the skills call (`BREW_TOOLS`: rtk, jira-cli, bitbucket-cli, gh, uv, bun, aws-sam-cli, mysql-client, redis, ollama, jq), Claude Code (`BREW_CASKS`), global bun packages (`bun update -g --latest`), uv tools (`uv tool upgrade --all`) |

It deletes nothing: skills removed upstream are listed for you to remove. AnythingLLM and Ollama
models are not touched. MCP servers started with `bunx` update themselves when their config uses
`@latest` (for example `bunx cachebro@latest serve`); the script does not touch them.
