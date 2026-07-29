#!/bin/bash
#
# ClawdPet hook — records only what Clawd needs in order to animate.
#
# PRIVACY, deliberately:
#   Claude Code hook payloads arrive on stdin and contain your raw prompt text,
#   tool inputs, tool results and transcript paths. This script extracts ONLY
#   three things — the event name, the tool name, and the notification type —
#   and passes each through a strict [A-Za-z0-9_-] filter before writing.
#   Prompt text, file contents, tool inputs/outputs, transcript paths and
#   session ids are never written anywhere, and nothing leaves this machine.
#
# Usage: hook.sh <EventName>   (payload on stdin)

set -u

EVENT="${1:-unknown}"
DIR="$HOME/.clawdpet"
STATE="$DIR/state.json"

mkdir -p "$DIR"

TOOL=""
NOTIFY=""

if [ ! -t 0 ]; then
    PAYLOAD="$(head -c 65536 2>/dev/null || true)"
    if [ -n "$PAYLOAD" ] && command -v jq >/dev/null 2>&1; then
        TOOL="$(printf '%s' "$PAYLOAD" | jq -r '.tool_name // ""' 2>/dev/null || true)"
        NOTIFY="$(printf '%s' "$PAYLOAD" | jq -r '.notification_type // ""' 2>/dev/null || true)"
    fi
    unset PAYLOAD
fi

# Belt and braces: even if the above ever returned something unexpected, only
# identifier-shaped characters can survive this.
TOOL="$(printf '%s' "$TOOL" | tr -cd 'A-Za-z0-9_-' | cut -c1-40)"
NOTIFY="$(printf '%s' "$NOTIFY" | tr -cd 'A-Za-z0-9_-' | cut -c1-40)"
EVENT="$(printf '%s' "$EVENT" | tr -cd 'A-Za-z0-9_-' | cut -c1-40)"

# Atomic write so the pet never reads a half-written file.
TMP="$(mktemp "$DIR/.state.XXXXXX")"
printf '{"event":"%s","tool":"%s","notify":"%s","ts":%s}\n' \
    "$EVENT" "$TOOL" "$NOTIFY" "$(date +%s)" > "$TMP"
mv -f "$TMP" "$STATE"

# Drain anything left on stdin so Claude never sees EPIPE writing to us. Read and
# thrown away — it is never stored, and never assigned to a variable.
cat > /dev/null 2>&1 || true

exit 0
