#!/bin/bash
# Registers ClawdPet's hooks in ~/.claude/settings.json.
# Only the "hooks" key is touched; every other setting is preserved.
set -euo pipefail
cd "$(dirname "$0")"

DIR="$HOME/.clawdpet"
SETTINGS="$HOME/.claude/settings.json"

mkdir -p "$DIR"
cp hook.sh "$DIR/hook.sh"
chmod +x "$DIR/hook.sh"

if [ ! -f "$SETTINGS" ]; then
    echo "No $SETTINGS found — nothing to patch." >&2
    exit 1
fi

cp "$SETTINGS" "$SETTINGS.clawdpet-backup"
echo "Backed up settings to $SETTINGS.clawdpet-backup"

HOOK="$DIR/hook.sh" python3 - "$SETTINGS" <<'PY'
import json, os, sys

settings_path = sys.argv[1]
hook = os.environ["HOOK"]

events = [
    "UserPromptSubmit", "PreToolUse", "PostToolUse",
    "Stop", "StopFailure", "Notification",
    "SubagentStart", "SubagentStop",
    "SessionStart", "SessionEnd",
]

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.get("hooks")
if not isinstance(hooks, dict):
    hooks = {}

for event in events:
    hooks[event] = [{
        "hooks": [{
            "type": "command",
            "command": hook,
            "args": [event],
            "async": True,
            "timeout": 2,
        }]
    }]

settings["hooks"] = hooks

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print("Registered %d hook events." % len(events))
PY

python3 -c "import json;json.load(open('$SETTINGS'));print('settings.json is valid JSON')"
echo "Done. Restart any running Claude Code session to pick the hooks up."
