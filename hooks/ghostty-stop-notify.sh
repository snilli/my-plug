#!/bin/bash
# Stop hook — native Ghostty desktop notification via OSC 9.
#
# Ghostty owns the notification, so clicking it focuses THIS terminal tab
# (not Script Editor). Under iTerm2 the ECC stop:desktop-notify already does
# this; under Ghostty it falls back to osascript -> Script Editor, so if you
# use ECC, disable its version with:  ECC_DISABLED_HOOKS=stop:desktop-notify
#
# ponytail: no frontmost-suppression, no dedup — fires on every Stop. Add later
# if the pings get noisy.
set -u

echo "[$(date '+%H:%M:%S')] stop-hook FIRED TERM_PROGRAM=${TERM_PROGRAM:-unset}" >> /tmp/my-plug-debug.log

[ "${TERM_PROGRAM:-}" = "ghostty" ] || exit 0
# tmux/screen swallow OSC 9
[ -n "${TMUX:-}" ] && exit 0
case "${TERM:-}" in screen*|tmux*) exit 0;; esac

RAW=$(cat)

# Summary = last assistant text line from the transcript, else "Done".
MSG="Done"
TP=$(printf '%s' "$RAW" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -n "${TP:-}" ] && [ -f "$TP" ]; then
  LAST=$(jq -rs '
    map(select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text)
    | last // empty' "$TP" 2>/dev/null | head -1)
  [ -n "${LAST:-}" ] && MSG=$(printf '%s' "$LAST" | cut -c1-100)
fi

# The hook runs detached from a tty; walk up the process tree to the terminal
# tab's controlling tty.
find_tty() {
  local pid=$$ depth=0 out ppid tty
  while [ "$depth" -lt 30 ]; do
    out=$(ps -o ppid=,tty= -p "$pid" 2>/dev/null) || return 1
    ppid=$(printf '%s' "$out" | awk '{print $1}')
    tty=$(printf '%s' "$out" | awk '{print $2}')
    case "$tty" in
      ''|'?'*) : ;;                                # no controlling tty at this level
      tty*) printf '/dev/%s\n' "$tty"; return 0 ;;
      *)    printf '/dev/tty%s\n' "$tty"; return 0 ;;
    esac
    { [ -z "$ppid" ] || [ "$ppid" -le 1 ]; } && return 1
    pid="$ppid"; depth=$((depth + 1))
  done
  return 1
}

TTY=$(find_tty) || { echo "[$(date '+%H:%M:%S')] no tty resolved — skip" >> /tmp/my-plug-debug.log; exit 0; }
echo "[$(date '+%H:%M:%S')] tty=$TTY emitting OSC9" >> /tmp/my-plug-debug.log

# Strip control chars (guards against OSC-injection from the message body).
CLEAN=$(printf '%s' "Claude Code: $MSG" | tr -d '\000-\037\177')
printf '\033]9;%s\007' "$CLEAN" > "$TTY" 2>/dev/null || true
exit 0
