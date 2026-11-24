---
name: update-all
description: Update everything the Claude Code setup depends on — every installed plugin (all marketplaces), every skill installed globally with the `skills` CLI, the brew CLIs the skills call (rtk, jira-cli, bitbucket-cli, gh, uv, bun, …), Claude Code itself, global bun packages (rea-agents, higgsfield, playwright, LSPs) and uv tools — then report what changed and what needs a decision. Use when the user asks to update, upgrade or refresh plugins, skills or tools, "อัปเดต plugin", "upgrade skill ทุกตัว", "update ทุกอย่าง", "rtk เวอร์ชันล่าสุดยัง", or asks whether anything is out of date. Not for installing something new or writing a skill.
---

# Update all plugins, skills and the tools they use

## 1. Run the updater

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-all.sh"            # everything
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-all.sh" plugins    # Claude Code plugins
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-all.sh" skills     # skills CLI skills
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-all.sh" tools      # brew/scoop CLIs, Claude Code, bun globals, uv tools
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-all.sh" sources    # list where each plugin/skill comes from; updates nothing
```

Works on macOS/Linux (bash) and Windows (Git Bash, which Claude Code uses there). It needs
`bun`; it does not need `jq`. On Windows it applies the **Windows profile**: only plugins from
`WIN_MARKETPLACES`, skills from `WIN_SKILL_SOURCES`, and scoop tools in `SCOOP_TOOLS` (`rtk`,
`bun`; scoop only, no winget) are updated; everything else is listed as skipped. Claude Code is
updated with `claude update`. rtk comes from the `r-bucket` scoop bucket (see `SOURCES.md`).
`UPDATE_ALL_OS=windows` forces the profile on another OS for testing. `SOURCES.md` next to this plugin is a dated
snapshot of the `sources` output.

It takes several minutes (one `claude plugin update` per plugin, one git clone per skill
source, brew downloads); run it in the background or with a long timeout. Sections:

| Section | What it runs |
|---|---|
| plugins | `claude plugin marketplace update`, then `claude plugin update <name>@<marketplace>` for each entry in `~/.claude/plugins/installed_plugins.json` |
| skills | `bunx skills update -g -y` from `$HOME` for `~/.agents/.skill-lock.json` (always `bunx`, never `npx`) |
| tools | macOS/Linux: `brew update`, `brew upgrade` of `BREW_TOOLS`, `brew upgrade --cask` of `BREW_CASKS` (Claude Code). Windows: `scoop update` of `SCOOP_TOOLS`, `claude update`. Both: `bun update -g --latest`, `uv tool upgrade --all` |

`BREW_TOOLS` and `BREW_CASKS` are at the top of the script. Only those are upgraded, not every
brew package on the machine. To add a tool a skill depends on, add its formula name there.

It deletes nothing. The skills CLI skips deleting skills that were removed upstream when it
runs non-interactively, and lists them under "deleted upstream".

## 2. Report

Tell the user, in their language:

- plugins that moved (old → new), the count already latest, and each `FAILED` one with its message;
- skills updated, and skills listed as deleted upstream. Do not delete them yourself; give the
  exact command and let the user decide: `bunx skills remove -g <name> <name> … -y`;
- brew tools / casks upgraded (from brew's output), bun globals and uv tools that changed;
- what was not touched (see Notes) when it is relevant;
- that new plugin and skill versions load only after `/reload-plugins` (or a restart), and a
  new Claude Code version only after a restart.

## Notes

- Not updated on purpose, report only:
  - AnythingLLM (`mintplexlabs/anythingllm`, pinned in the incidents docker compose) and Ollama
    models — a version change can need a re-embed; update them by hand.
  - MCP servers started with `bunx` are not updated by the script. Give them `@latest` in their
    config (`bunx cachebro@latest serve`, `bunx -y @mui/mcp@latest`) so each start pulls the newest
    version. If one is started as `bunx <pkg>` with no version, it keeps the cached copy; point it
    out to the user and suggest re-adding it with `@latest` (`claude mcp add-json … -s user`).
  - Project-scoped plugins and skills (`.claude/` inside a repo) and hand-made folders in
    `~/.claude/skills` that are not in the skills lockfile.
- `bunx skills update -g` without `-y` prompts for deletions and cannot answer through Claude
  Code's `!` or a tool call, so it stops early. Use the script.
- `rtk` is a brew formula; after an upgrade its Claude Code hook keeps working (it calls the
  `rtk` binary on PATH). Check with `rtk --version`.
