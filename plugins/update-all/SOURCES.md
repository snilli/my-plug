# Where my plugins and skills come from

Snapshot of 2026-10-27. Regenerate the live list with:

```
bash plugins/update-all/scripts/update-all.sh sources
```

## Plugin marketplaces (`claude plugin`)

| Marketplace | Source | Plugins in use |
|---|---|---|
| `claude-plugins-official` | `anthropics/claude-plugins-official` | `superpowers`, `figma`, `cloudflare`, `aws-serverless`, `plugin-dev`, `mattpocock-skills`, `deploy-on-aws`, `frontend-design`, `skill-creator`, `remember`, `code-review`, `commit-commands`, `feature-dev`, `pr-review-toolkit`, `claude-md-management`, `claude-code-setup`, `code-simplifier`, `agent-sdk-dev`, `learning-output-style`, `playwright`, LSPs (`php`, `gopls`, `pyright`, `typescript`) |
| `anthropic-plugin-directory` | built into Claude Code | `typescript-native-lsp` |
| `ecc` | `github.com/affaan-m/ECC` | `ecc` (293 skills, 94 commands) |
| `ez-plugin` | `snilli/ez-plugin` | `ez` |
| `my-plug` | `snilli/my-plug` | `ghostty-stop-notify`, `update-all` |
| `ponytail` | `DietrichGebert/ponytail` | `ponytail` |
| `ui-ux-pro-max-skill` | `nextlevelbuilder/ui-ux-pro-max-skill` | `ui-ux-pro-max` |
| `claude-powerline` | `Owloops/claude-powerline` | `claude-powerline` |
| `answer-me-with-html` | `QingYunA/answer-me-with-html` | `answer-me-with-html` |

## Skills installed with the `skills` CLI (`~/.agents/.skill-lock.json`)

| Source | Count | Skills |
|---|---|---|
| `vercel-labs/agent-skills` | 9 | `vercel-*`, `web-design-guidelines`, `deploy-to-vercel` |
| `paramchoudhary/resumeskills` | 10 | `resume-*`, `academic-cv-builder`, `tech-resume-optimizer`, `application-form-filler` |
| `higgsfield-ai/skills` | 8 | `higgsfield-*` |
| `shadcn/ui` | 2 | `shadcn`, `migrate-radix-to-base` |
| `avivsinai/bitbucket-cli` | 1 | `bkt` |
| `code-and-sorts/awesome-copilot-agents` | 1 | `jira-cli` |
| `tt-a1i/archify` | 1 | `archify` |
| `nutlope/hallmark` | 1 | `hallmark` |
| `intentui/skills` | 1 | `intentui` |
| `gbrasil720/ui-sensei` | 1 | `ui-sensei` |
| `Leonxlnx/taste-skill` | 1 | `design-taste-frontend` (12 others removed upstream and uninstalled on 2026-10-27) |

## No tracked source (not updated automatically)

`reverse-engineer-anything`, `learned`, `synced` — folders in
`~/.claude/skills` that are not in the skills lockfile.

## Windows profile

On Windows the updater touches only these (`WIN_MARKETPLACES`, `WIN_SKILL_SOURCES`,
`SCOOP_TOOLS` in the script); anything else installed there is skipped.

| Kind | Kept on Windows |
|---|---|
| Plugin marketplaces | `claude-plugins-official` (incl. `mattpocock-skills`), `anthropic-plugin-directory`, `ecc`, `my-plug`, `ponytail`, `answer-me-with-html` |
| skills CLI | `tt-a1i/archify` |
| scoop tools | `rtk`, `bun` |
| MCP | `cachebro` (`bunx cachebro@latest serve`, updates itself) |
| Not used on Windows | `ez-plugin`, `jira-cli`, `bitbucket-cli`, `intentui/skills`, `gbrasil720/ui-sensei`, `Leonxlnx/taste-skill`, `code-and-sorts/awesome-copilot-agents`, `shadcn/ui`, `vercel-labs/agent-skills` |

Install rtk on Windows (PowerShell). The package is `rtk-ai/rtk`, the same tool as brew's `rtk`:

```powershell
scoop bucket add r-bucket https://github.com/cderv/r-bucket
scoop install rtk
rtk init --global
```

## Tools the skills call

| Tool | Installed with |
|---|---|
| `rtk`, `jira-cli`, `bitbucket-cli`, `gh`, `uv`, `bun`, `aws-sam-cli`, `mysql-client`, `redis`, `ollama` | brew |
| Claude Code | brew cask `claude-code@latest` |
| `rea-agents`, `@higgsfield/cli`, `@owloops/claude-powerline`, `playwright`, `intelephense`, `typescript-language-server` | `bun add -g` |
| `cfn-lint`, `gflow-cli` | `uv tool` |
| MCP `cachebro` (`bunx cachebro@latest serve`), `mui-mcp` (`bunx -y @mui/mcp@latest`), `rea` (`rea-agents mcp`) | MCP servers in `~/.claude.json` |
| AnythingLLM `mintplexlabs/anythingllm`, Ollama models | docker / ollama, updated by hand |
