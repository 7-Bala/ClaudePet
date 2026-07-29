import Cocoa

/// A window that never takes focus — clicking Clawd must not pull you out of
/// whatever you were typing in.
final class PetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private static let sizeDefaultsKey = "ClawdCellSize"

    private var window: PetWindow!
    private var view: ClawdView!

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
        window.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.placeOnDock(initial: false)
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
