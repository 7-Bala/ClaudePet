# 🦀 ClawdPet

**ClawdPet** is a native macOS desktop companion application built with Swift and Cocoa/AppKit. It places a pixel art mascot ("Clawd") directly on your macOS Dock bar that reacts in real-time to your **Claude Code** CLI session activity.

![ClawdPet](https://raw.githubusercontent.com/7-Bala/ClaudePet/main/preview.png) *(or screenshot)*

---

## 🎨 Features

- **Non-Intrusive**: Runs as a transparent macOS accessory window (`.accessory`) docked right above your Dock. It never takes keyboard focus, so clicking or dragging Clawd won't interrupt your workflow.
- **Real-Time Reactions**: Responds to Claude Code CLI events:
  - **Tool Execution** (`Bash`, `Edit`, `Write`, `Read`, `Grep`, `Search`): Clawd jumps, spins, or inspects based on what Claude is doing.
  - **User Attention Required**: When Claude pauses for user input or permissions, Clawd enters a custom asking/waving loop.
  - **Turn Finish**: Celebrates when Claude completes a task.
- **Interactive Physics**: Drag and drop Clawd anywhere on your screen. Drop it to watch it fall back down to your Dock with smooth gravity physics and dynamic ground shadowing.
- **Context Menu Options**: Right-click Clawd to adjust sprite scale (**Small 3x**, **Medium 4x**, **Large 6x**), check current status, or put Clawd away.
- **Privacy-First**: The hook script extracts only event names and tool types via strict filtering. Prompt texts, code contents, transcripts, and session IDs are never recorded or transmitted.

---

## 🚀 Quick Start

### 1. Build from Source

Ensure you are on macOS with Swift installed (`swiftc`).

```bash
chmod +x build.sh
./build.sh
```

This compiles the Swift sources and produces `ClawdPet.app`.

### 2. Run ClawdPet

Launch `ClawdPet.app`:

```bash
open ClawdPet.app
```

### 3. Install Claude Code Hooks

To enable real-time animation reactions, install the event hook into your `~/.claude/settings.json`:

```bash
chmod +x install-hooks.sh
./install-hooks.sh
```

*(Optional)* To start ClawdPet automatically when logging into macOS:

```bash
chmod +x install-loginitem.sh
./install-loginitem.sh
```

---

## 🛠️ Project Structure

- **`main.swift`** — Initializes the macOS application lifecycle.
- **`PetWindow.swift`** — Creates a borderless, non-focusing floating window anchored to the Dock.
- **`ClawdView.swift`** — Manages rendering, animation ticks (60 FPS), movement physics, and mouse events.
- **`Sprite.swift`** — 24×15 pixel art grid engine rendering Clawd and ground poofs.
- **`Animation.swift`** — Animation sequence controller (poses, working cycles, fidgets).
- **`TaskMonitor.swift`** — Monitors active Claude Code sessions and state updates.
- **`hook.sh`** — Lightweight, privacy-conscious event logger called by Claude Code hooks.

---

## 📄 License

MIT License. Feel free to use, modify, and distribute!
