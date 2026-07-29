#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="ClawdPet.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O \
  Sprite.swift \
  Animation.swift \
  TaskMonitor.swift \
  ClawdView.swift \
  PetWindow.swift \
  main.swift \
  -o "$APP/Contents/MacOS/ClawdPet"

cp Info.plist "$APP/Contents/Info.plist"

codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "Built $APP"
