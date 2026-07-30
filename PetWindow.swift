import Cocoa

/// A window that never takes focus — clicking Clawd must not pull you out of
/// whatever you were typing in.
final class PetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private static let sizeDefaultsKey = "ClawdCellSize"

    /// Clawd only shows up while the actual Claude desktop app is running —
    /// this is its bundle identifier, confirmed against the installed app at
    /// /Applications/Claude.app.
    private static let claudeBundleID = "com.anthropic.claudefordesktop"

    private var window: PetWindow!
    private var view: ClawdView!
    private var visibilityPollTimer: Timer?
    private var isShown = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // The login item and a manual launch can race; only one Clawd, please.
        if let id = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: id).count > 1 {
            NSApp.terminate(nil)
            return
        }

        let stored = UserDefaults.standard.double(forKey: Self.sizeDefaultsKey)
        let cellSize: CGFloat = stored > 0 ? CGFloat(stored) : 4

        view = ClawdView(cellSize: cellSize)
        view.onSizeChange = { [weak self] newWidth in self?.resize(to: newWidth) }

        let size = ClawdView.canvasSize(cellSize: cellSize)
        window = PetWindow(contentRect: NSRect(origin: .zero, size: size),
                           styleMask: [.borderless],
                           backing: .buffered,
                           defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        // .floating is level 3, which is *below* the Dock at 20 — Clawd would slip
        // behind it when dragged over. Sit just above the Dock instead.
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = false
        window.ignoresMouseEvents = false
        window.contentView = view

        placeOnDock(initial: true)
        // Start hidden; updateVisibility() below decides whether to show it.
        window.orderOut(nil)

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.placeOnDock(initial: false)
        }

        // The primary signal: NSWorkspace tells us the instant Claude launches
        // or quits, so Clawd appears/disappears essentially immediately.
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == Self.claudeBundleID else { return }
            self?.updateVisibility()
        }
        workspace.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == Self.claudeBundleID else { return }
            self?.updateVisibility()
        }

        // Belt and suspenders: a slow poll in case a notification is ever missed
        // (e.g. Claude force-quit while this process itself was suspended).
        let poll = Timer(timeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.updateVisibility()
        }
        RunLoop.main.add(poll, forMode: .common)
        visibilityPollTimer = poll

        updateVisibility()
    }

    private func isClaudeRunning() -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: Self.claudeBundleID).isEmpty
    }

    private func updateVisibility() {
        let shouldShow = isClaudeRunning()
        guard shouldShow != isShown else { return }
        isShown = shouldShow

        if shouldShow {
            placeOnDock(initial: false)
            window.orderFrontRegardless()
        } else {
            window.orderOut(nil)
        }
    }

    /// Parks Clawd with its feet on the top edge of the Dock.
    private func placeOnDock(initial: Bool) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        let x = initial
            ? screen.visibleFrame.midX - window.frame.width / 2
            : min(max(window.frame.origin.x, screen.frame.minX),
                  screen.frame.maxX - window.frame.width)
        window.setFrameOrigin(NSPoint(x: round(x), y: round(view.groundOriginY())))
        view.syncPosition()
    }

    private func resize(to cellSize: CGFloat) {
        UserDefaults.standard.set(Double(cellSize), forKey: Self.sizeDefaultsKey)

        let centreX = window.frame.midX
        let size = ClawdView.canvasSize(cellSize: cellSize)
        view.apply(cellSize: cellSize)
        window.setContentSize(size)

        guard let screen = window.screen ?? NSScreen.main else { return }
        let x = min(max(centreX - size.width / 2, screen.frame.minX),
                    screen.frame.maxX - size.width)
        window.setFrameOrigin(NSPoint(x: round(x), y: round(view.groundOriginY())))
        view.syncPosition()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
