#!/bin/bash
# Starts Clawd automatically at login via a LaunchAgent.
set -euo pipefail
cd "$(dirname "$0")"

APP="$(pwd)/ClawdPet.app/Contents/MacOS/ClawdPet"
PLIST="$HOME/Library/LaunchAgents/com.local.clawdpet.plist"
LABEL="com.local.clawdpet"

if [ ! -x "$APP" ]; then
    echo "Build it first: ./build.sh" >&2
    exit 1
fi

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$LABEL</string>
	<key>ProgramArguments</key>
	<array>
		<string>$APP</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<false/>
	<key>ProcessType</key>
	<string>Interactive</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "Installed login item at $PLIST"
launchctl print "gui/$(id -u)/$LABEL" 2>/dev/null | head -4 || true
