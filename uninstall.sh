#!/bin/bash
# Removes everything ClawdPet installed: hooks, login item, state directory.
set -uo pipefail

SETTINGS="$HOME/.claude/settings.json"
PLIST="$HOME/Library/LaunchAgents/com.local.clawdpet.plist"

echo "Stopping Clawd..."
launchctl bootout "gui/$(id -u)/com.local.clawdpet" 2>/dev/null || true
pkill -f ClawdPet.app 2>/dev/null || true
rm -f "$PLIST"

if [ -f "$SETTINGS" ]; then
    python3 - "$SETTINGS" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    settings = json.load(f)
hooks = settings.get("hooks")
if isinstance(hooks, dict):
    for event in list(hooks):
        groups = hooks[event]
        kept = []
        for group in groups:
            inner = [h for h in group.get("hooks", [])
                     if "clawdpet" not in str(h.get("command", ""))]
            if inner:
                group["hooks"] = inner
                kept.append(group)
        if kept:
            hooks[event] = kept
        else:
            del hooks[event]
    settings["hooks"] = hooks
with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
print("Removed ClawdPet hooks; other settings untouched.")
PY
fi

rm -rf "$HOME/.clawdpet"
echo "Done. ClawdPet is fully removed."
