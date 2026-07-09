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
```
