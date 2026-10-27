#!/usr/bin/env bash
# Update every installed Claude Code plugin, every globally installed `skills` CLI skill, and the
# CLIs the skills call. Prints what changed. Deletes nothing.
#
#   update-all.sh            plugins + skills + tools
#   update-all.sh plugins    Claude Code plugins only
#   update-all.sh skills     skills CLI skills only
#   update-all.sh tools      CLIs (brew on macOS/Linux, scoop on Windows), Claude Code,
#                            bun globals, uv tools
#   update-all.sh sources    print where every plugin and skill comes from (no updates)
#
# Runs in bash: Terminal on macOS/Linux, Git Bash on Windows (what Claude Code uses there).
# Needs bun (JSON parsing and the skills CLI). No jq, no npx.
set -uo pipefail

# Package-manager names of the CLIs the skills and hooks call. Only these are upgraded.
BREW_TOOLS=(rtk jira-cli bitbucket-cli gh uv bun aws-sam-cli mysql-client redis ollama jq)
BREW_CASKS=(claude-code@latest)
# Windows profile: only these are updated on Windows; everything else installed there is skipped.
WIN_MARKETPLACES=(claude-plugins-official anthropic-plugin-directory ecc my-plug ponytail answer-me-with-html)
WIN_SKILL_SOURCES=(tt-a1i/archify)
SCOOP_TOOLS=(rtk bun)                               # Windows: scoop only (no winget)

WHAT="${1:-all}"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
INSTALLED="$CLAUDE_HOME/plugins/installed_plugins.json"
MARKETPLACES="$CLAUDE_HOME/plugins/known_marketplaces.json"
LOCK="$HOME/.agents/.skill-lock.json"

case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) OS=windows ;; Darwin) OS=mac ;; *) OS=linux ;; esac
OS="${UPDATE_ALL_OS:-$OS}"   # override for testing a profile, e.g. UPDATE_ALL_OS=windows
strip() { sed 's/\x1b\[[0-9;]*[A-Za-z]//g' | tr -d '\r'; }
in_list() { local x="$1"; shift; local i; for i in "$@"; do [[ "$i" == "$x" ]] && return 0; done; return 1; }
has() { command -v "$1" >/dev/null 2>&1; }
# Evaluate a JS expression over a JSON file with bun; `d` is the parsed file. Prints one item per line.
json() { bun -e "const d=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); const r=($2); console.log([].concat(r).join('\n'))" "$1" 2>/dev/null | tr -d '\r'; }

if ! has bun; then
  echo "[FATAL] bun not found. Install it first: https://bun.sh (macOS: brew install bun; Windows: scoop install bun)"
  exit 2
fi

if [[ "$WHAT" == sources ]]; then
  echo "== Plugin marketplaces"
  [[ -f "$MARKETPLACES" ]] && json "$MARKETPLACES" 'Object.entries(d).map(([k,v]) => k.padEnd(26) + (v.source.repo || v.source.url || v.source.path || v.source.source))'
  echo "== Installed plugins (name@marketplace)"
  [[ -f "$INSTALLED" ]] && json "$INSTALLED" 'Object.keys(d.plugins).map(k => "  " + k)'
  echo "== skills CLI sources"
  [[ -f "$LOCK" ]] && json "$LOCK" 'Object.entries(Object.entries(d.skills).reduce((a,[n,s]) => ((a[s.source] ??= []).push(n), a), {})).map(([src,ns]) => src.padEnd(40) + ns.length + "  " + ns.join(", "))'
  echo "== Skills with no tracked source"
  for d in "$CLAUDE_HOME"/skills/*/; do
    n=$(basename "$d")
    [[ -f "$LOCK" ]] && json "$LOCK" "Object.keys(d.skills).includes('$n') ? 'x' : ''" | grep -q x && continue
    echo "  $n"
  done
  exit 0
fi

if [[ "$WHAT" == all || "$WHAT" == plugins ]]; then
  echo "== Plugins"
  if ! has claude; then
    echo "[SKIP] claude CLI not found"
  elif [[ ! -f "$INSTALLED" ]]; then
    echo "[SKIP] $INSTALLED not found"
  else
    claude plugin marketplace update 2>&1 | strip | tail -1
    updated=0
    while IFS= read -r plugin; do
      [[ -z "$plugin" ]] && continue
      if [[ "$OS" == windows ]] && ! in_list "${plugin##*@}" "${WIN_MARKETPLACES[@]}"; then
        echo "  skip     $plugin (not in the Windows profile)"; continue
      fi
      out=$(claude plugin update "$plugin" 2>&1 | strip | tail -1)
      case "$out" in
        *"updated from"*) updated=$((updated + 1)); echo "  UPDATED  $plugin — $out" ;;
        *"already at the latest"*) echo "  latest   $plugin" ;;
        *) echo "  FAILED   $plugin — $out" ;;
      esac
    done < <(json "$INSTALLED" 'Object.keys(d.plugins)')
    echo "  $updated plugin(s) updated. Run /reload-plugins (or restart) to load them."
  fi
fi

if [[ "$WHAT" == all || "$WHAT" == skills ]]; then
  echo "== Skills (skills CLI, global)"
  if [[ ! -f "$LOCK" ]]; then
    echo "[SKIP] $LOCK not found — no skills installed with the skills CLI"
  else
    names=()
    if [[ "$OS" == windows ]]; then
      # Windows profile: only skills whose source is in WIN_SKILL_SOURCES.
      srcs=$(printf "'%s'," "${WIN_SKILL_SOURCES[@]}")
      while IFS= read -r n; do [[ -n "$n" ]] && names+=("$n"); done \
        < <(json "$LOCK" "Object.entries(d.skills).filter(([n,s]) => [${srcs%,}].includes(s.source)).map(([n]) => n)")
      echo "  Windows profile: ${names[*]:-(none installed)}"
      ((${#names[@]})) || names=(__none__)
    fi
    if [[ "${names[*]:-}" != __none__ ]]; then
      # -y answers yes to updates; deletions of skills removed upstream are skipped in non-interactive mode.
      (cd "$HOME" && bunx skills update -g -y ${names[@]+"${names[@]}"} 2>&1) | strip | grep -v '^\s*$' \
        | grep -E 'Found|Updated|✓|Warning|deleted upstream|^\s+•|Skipping|No updates|up to date'
    fi
  fi
fi

if [[ "$WHAT" == all || "$WHAT" == tools ]]; then
  echo "== Tools ($OS)"
  if [[ "$OS" == windows ]]; then
    if has scoop; then
      scoop update >/dev/null 2>&1
      installed=()
      for t in "${SCOOP_TOOLS[@]}"; do scoop prefix "$t" >/dev/null 2>&1 && installed+=("$t"); done
      if ((${#installed[@]})); then
        scoop update "${installed[@]}" 2>&1 | strip | grep -E -i 'updating|updated|latest|error' | sed 's/^/    /'
      else
        echo "  scoop: none of ${SCOOP_TOOLS[*]} installed"
      fi
    else
      echo "  [SKIP] scoop not found (Windows tools are updated with scoop only)"
    fi
    # Claude Code's native Windows install updates itself; this asks it to now.
    has claude && claude update 2>&1 | strip | tail -2 | sed 's/^/    claude: /'
  elif has brew; then
    brew update --quiet >/dev/null 2>&1
    installed=()
    for f in "${BREW_TOOLS[@]}"; do brew list --formula "$f" >/dev/null 2>&1 && installed+=("$f"); done
    outdated=$( ((${#installed[@]})) && brew outdated --formula "${installed[@]}" 2>/dev/null)
    if [[ -n "$outdated" ]]; then
      echo "  brew formulae to upgrade:"; echo "$outdated" | sed 's/^/    /'
      brew upgrade --formula "${installed[@]}" 2>&1 | strip | grep -E '^==> (Upgrading|Pouring)|Error' | sed 's/^/    /'
    else
      echo "  brew formulae: all latest (${installed[*]})"
    fi
    for c in "${BREW_CASKS[@]}"; do
      brew list --cask "$c" >/dev/null 2>&1 || continue
      if [[ -n "$(brew outdated --cask --greedy "$c" 2>/dev/null)" ]]; then
        brew upgrade --cask --greedy "$c" 2>&1 | strip | grep -E 'Upgrading|upgraded|Error' | sed 's/^/    /'
      else
        echo "  cask $c: latest"
      fi
    done
  else
    echo "  [SKIP] brew not found"
    has claude && claude update 2>&1 | strip | tail -2 | sed 's/^/    claude: /'
  fi
  echo "  bun global packages:"
  bun update -g --latest 2>&1 | strip | grep -E '^\s*[↑+]|installed|no changes|error' | sed 's/^/    /'
  if has uv; then
    echo "  uv tools:"
    # Keep the per-tool lines ("Updated cfn-lint v1 -> v2", "Nothing to upgrade"), not every dependency.
    uv tool upgrade --all 2>&1 | strip | grep -E '^(Updated|Nothing|Modified)|error' | sed 's/^/    /'
  fi
fi
