import Cocoa

/// Renders Clawd and owns its behaviour: reacting to Claude Code activity,
/// idling with personality, and putting on its chef costume to cook
/// continuously for as long as a task is running.
final class ClawdView: NSView {

    // MARK: Layout

    private(set) var cellSize: CGFloat

    private static let padCols = 5
    private static let padTop = 8
    private static let padBottom = 1

    static func canvasSize(cellSize cell: CGFloat) -> NSSize {
        NSSize(width: CGFloat(ClawdSprite.cols + padCols * 2) * cell,
               height: CGFloat(ClawdSprite.rows + padTop + padBottom) * cell)
    }

    static func feetInset(cellSize cell: CGFloat) -> CGFloat {
        CGFloat(padBottom) * cell
    }

    private var hopRoom: CGFloat { CGFloat(ClawdView.padTop) * cellSize }

    // MARK: State

    private let animator = Animator()
    private let monitor = TaskMonitor()

    private var mood: Mood = .asleep

    /// Right-click → "Play Cooking Animation" — forces the cooking loop on
    /// regardless of what Claude is actually doing, until switched off again.
    /// Testing only: lets you eyeball the costume without waiting for a real
    /// tool call to trigger it.
    private var testCookingLoop = false

    /// True from the moment the hat-on transition starts until the hat-off
    /// transition finishes. This is what lets the costume go on exactly once
    /// at the start of a task and come off exactly once when it ends, rather
    /// than replaying the whole put-on/take-off cycle for every tool call —
    /// which is what made it read as an obviously looping clip before.
    private var costumeOn = false

    /// Horizontal position. Clawd stays put above the Dock — it moves only
    /// when dragged or when hopping in place — so this is the sole owner of
    /// the window's x, with no separate wandering system to fight it.
    private var posX: CGFloat = 0

    private var elevation: CGFloat = 0
    private var verticalVelocity: CGFloat = 0
    private var isHeld = false
    private var landingCrouch = 0

    private var dragOriginMouse: NSPoint = .zero
    private var dragOriginWindow: NSPoint = .zero
    private var didDrag = false

    private var nextFidgetAt = Date().addingTimeInterval(4)

    private var timer: Timer?
    private var lastTick = Date()
    private var lastRenderKey = ""

    var onSizeChange: ((CGFloat) -> Void)?

    // MARK: Init

    init(cellSize: CGFloat) {
        self.cellSize = cellSize
        super.init(frame: NSRect(origin: .zero, size: ClawdView.canvasSize(cellSize: cellSize)))
        wantsLayer = true

        monitor.onEvent = { [weak self] event, tool in
            self?.react(to: event, tool: tool)
        }

        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    deinit { timer?.invalidate() }

    // MARK: Behaviour
    //
    // What Clawd does while a task is running is context-aware rather than
    // one fixed costume: the tool Claude is actually using picks the prop.
    // Only cooking (Bash) gets the full hat ceremony; editing and reading
    // are lighter instant prop swaps, matching how little fuss the reel's
    // own prop changes made of themselves.

    /// Which tool-shaped activity is currently playing.
    private enum Activity: Equatable {
        case none      // no tool active yet, or an unmapped one — no prop
        case cooking   // Bash — chef hat + pan, continuous toss
        case typing    // Edit/Write/NotebookEdit/MultiEdit — keyboard, hand taps
        case reading   // Read/Grep/Glob/WebFetch/WebSearch — small terminal
    }

    private var currentActivity: Activity = .none

    private func react(to event: String, tool: String?) {
        switch event {
        case "SubagentStart", "SubagentStop":
            animator.play(Sequences.spin)
        case "PostToolUseFailure":
            animator.play(Sequences.flinch)
        case "PreToolUse":
            if tool == "AskUserQuestion" || tool == "ExitPlanMode" {
                animator.play(Sequences.asking)
            }
            if !testCookingLoop, mood == .working {
                setActivity(Self.activity(for: tool))
            }
        default:
            break
        }
    }

    private static func activity(for tool: String?) -> Activity {
        switch tool {
        case "Bash":
            return .cooking
        case "Edit", "Write", "NotebookEdit", "MultiEdit":
            return .typing
        case "Read", "Grep", "Glob", "WebFetch", "WebSearch":
            return .reading
        default:
            return .none
        }
    }

    private func loop(for activity: Activity) -> [Frame] {
        switch activity {
        case .none:    return Sequences.workingIdle
        case .cooking: return Sequences.cookLoop
        case .typing:  return Sequences.typingLoop
        case .reading: return Sequences.readingLoop
        }
    }

    /// Switches the active tool-shaped costume. Crossing in or out of
    /// `.cooking` plays the hat on/off gesture; any other switch is an
    /// instant prop swap — no ceremony, matching how plainly the reel's own
    /// props changed.
    private func setActivity(_ activity: Activity) {
        guard activity != currentActivity else { return }
        let hadHat = costumeOn
        currentActivity = activity
        costumeOn = (activity == .cooking)

        animator.setLoop(loop(for: activity))

        if costumeOn && !hadHat {
            animator.playImmediately(Sequences.hatOnTransition)
        } else if !costumeOn && hadHat {
            animator.playImmediately(Sequences.hatOffTransition)
        }
    }

    /// Drops whatever activity was playing — taking the hat off first if it
    /// was on — and settles into `thenLoop`, optionally through a one-shot
    /// flourish (the little celebration when a task finishes).
    private func endActivity(thenLoop: [Frame], flourish: [Frame] = []) {
        let hadHat = costumeOn
        currentActivity = .none
        costumeOn = false
        animator.setLoop(thenLoop)

        if hadHat {
            animator.playImmediately(Sequences.hatOffTransition + flourish)
        } else if !flourish.isEmpty {
            animator.playImmediately(flourish)
        }
    }

    private func loopForCurrentState() -> [Frame] {
        switch mood {
        case .asleep:      return Sequences.sleeping
        case .working:     return Sequences.workingIdle
        case .waiting:     return Sequences.asking
        case .celebrating: return Sequences.idle
        }
    }

    private func moodChanged(to newMood: Mood) {
        mood = newMood
        scheduleNextFidget()

        // The testing toggle owns the costume while it's on — a real mood
        // change underneath it shouldn't touch the animation.
        guard !testCookingLoop else { return }

        switch newMood {
        case .working:
            // Nothing to show yet — the first PreToolUse picks the activity.
            setActivity(.none)
        case .asleep:
            endActivity(thenLoop: Sequences.sleeping)
        case .waiting:
            endActivity(thenLoop: Sequences.asking)
        case .celebrating:
            endActivity(thenLoop: Sequences.idle, flourish: Sequences.celebrate)
        }
    }

    @objc private func toggleCookingTest() {
        testCookingLoop.toggle()
        if testCookingLoop {
            setActivity(.cooking)
        } else if mood == .working {
            // A real task is genuinely running — drop back to neutral and
            // let the next real tool event re-sync the activity.
            setActivity(.none)
        } else {
            endActivity(thenLoop: loopForCurrentState())
        }
    }

    private func scheduleNextFidget() {
        nextFidgetAt = Date().addingTimeInterval(Double.random(in: 5.0...13.0))
    }

    private func maybeFidget(now: Date) {
        // Every tool-shaped activity already has something happening on
        // screen — idle fidgets are only for when Clawd is genuinely asleep.
        guard !testCookingLoop, !costumeOn, mood == .asleep else { return }
        guard now >= nextFidgetAt, !animator.isBusy, !isHeld, elevation == 0 else { return }
        scheduleNextFidget()

        animator.play(Double.random(in: 0...1) < 0.65
                      ? Sequences.sleepFidget()
                      : Sequences.idleFidget())
    }

    // MARK: Tick

    private func tick() {
        let now = Date()
        let dt = min(now.timeIntervalSince(lastTick), 0.1)
        lastTick = now

        monitor.poll()
        if monitor.mood != mood { moodChanged(to: monitor.mood) }

        animator.advance(by: dt)

        stepPhysics(dt: CGFloat(dt))
        maybeFidget(now: now)

        if landingCrouch > 0 { landingCrouch -= 1 }
        redrawIfNeeded()
    }

    // MARK: Horizontal movement

    private func horizontalBounds() -> (min: CGFloat, max: CGFloat) {
        guard let window = window, let screen = window.screen ?? NSScreen.main else { return (0, 0) }
        let maxX = max(screen.frame.minX, screen.frame.maxX - window.frame.width)
        return (screen.frame.minX, maxX)
    }

    // MARK: Vertical movement

    private func stepPhysics(dt: CGFloat) {
        guard !isHeld else { return }
        guard elevation > 0 || verticalVelocity != 0 else { return }

        verticalVelocity -= 1400 * dt
        elevation += verticalVelocity * dt

        if elevation <= 0 {
            elevation = 0
            verticalVelocity = 0
            landingCrouch = 5
        }
        applyPosition()
    }

    func groundOriginY() -> CGFloat {
        guard let screen = window?.screen ?? NSScreen.main else { return 0 }
        return screen.visibleFrame.minY - ClawdView.feetInset(cellSize: cellSize)
    }

    private func applyPosition() {
        guard let window = window else { return }
        let bounds = horizontalBounds()
        posX = min(max(posX, bounds.min), bounds.max)
        let y = groundOriginY() + max(0, elevation - hopRoom)
        window.setFrameOrigin(NSPoint(x: round(posX), y: round(y)))
    }

    func syncPosition() {
        posX = window?.frame.origin.x ?? posX
    }

    // MARK: Drawing

    private func redrawIfNeeded() {
        let f = animator.current
        let key = "\(f.pose)|\(f.offset)|\(f.poof.map(String.init(describing:)) ?? "-")|\(landingCrouch > 0)|\(Int(elevation))"
        if key != lastRenderKey {
            lastRenderKey = key
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        ctx.setShouldAntialias(false)
        ctx.interpolationQuality = .none

        let cell = cellSize
        let frame = animator.current

        let crouch = frame.offset + (landingCrouch > 0 ? 2 : 0)
        let lift = min(elevation, hopRoom)
        let originX = CGFloat(ClawdView.padCols) * cell
        let groundY = CGFloat(ClawdView.padBottom) * cell
        let originY = groundY - crouch * cell + lift

        if lift > 0.5, elevation <= hopRoom {
            let t = min(lift / hopRoom, 1)
            let full = CGFloat(ClawdSprite.cols - 8) * cell
            let width = full * (1 - t * 0.35)
            let shadow = CGRect(x: bounds.midX - width / 2,
                                y: groundY - cell,
                                width: width,
                                height: cell)
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.18 * (1 - t * 0.7)).cgColor)
            ctx.fill(shadow)
        }

        if let poof = frame.poof {
            ClawdSprite.drawPoof(in: ctx, kind: poof, originX: originX, originY: originY, cell: cell)
        }

        ClawdSprite.draw(in: ctx, pose: frame.pose, originX: originX, originY: originY, cell: cell)
    }

    // MARK: Mouse

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        let cell = cellSize
        let sprite = NSRect(x: CGFloat(ClawdView.padCols) * cell,
                            y: CGFloat(ClawdView.padBottom) * cell,
                            width: CGFloat(ClawdSprite.cols) * cell,
                            height: CGFloat(ClawdSprite.rows) * cell)
        return sprite.contains(local) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        didDrag = false
        isHeld = true
        verticalVelocity = 0
        dragOriginMouse = NSEvent.mouseLocation
        dragOriginWindow = window?.frame.origin ?? .zero
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = window else { return }
        let current = NSEvent.mouseLocation
        let dx = current.x - dragOriginMouse.x
        let dy = current.y - dragOriginMouse.y
        if abs(dx) + abs(dy) > 3 { didDrag = true }

        let bounds = horizontalBounds()
        posX = min(max(dragOriginWindow.x + dx, bounds.min), bounds.max)
        elevation = max(0, (dragOriginWindow.y + dy) - groundOriginY()) + hopRoom
        _ = window
        applyPosition()
    }

    override func mouseUp(with event: NSEvent) {
        isHeld = false
        if didDrag {
            verticalVelocity = 0
        } else {
            animator.play(Sequences.clickReaction(), minimumGap: 0)
            verticalVelocity = 200
            elevation = 0.01
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        for (title, value) in [("Small", CGFloat(3)), ("Medium", CGFloat(4)), ("Large", CGFloat(6))] {
            let item = NSMenuItem(title: title, action: #selector(changeSize(_:)), keyEquivalent: "")
            item.target = self
            item.tag = Int(value)
            item.state = (value == cellSize) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let cookTest = NSMenuItem(title: "Play Cooking Animation (Testing)",
                                  action: #selector(toggleCookingTest), keyEquivalent: "")
        cookTest.target = self
        cookTest.state = testCookingLoop ? .on : .off
        menu.addItem(cookTest)

        menu.addItem(.separator())
        let status = NSMenuItem(title: statusLine(), action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Put Clawd away", action: #selector(quit), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    private func statusLine() -> String {
        if testCookingLoop { return "Testing: cooking animation" }
        switch mood {
        case .asleep:      return "Sleeping"
        case .working:     return "Claude is working"
        case .waiting:     return "Claude needs you"
        case .celebrating: return "Just finished"
        }
    }

    @objc private func changeSize(_ sender: NSMenuItem) {
        onSizeChange?(CGFloat(sender.tag))
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func apply(cellSize cell: CGFloat) {
        cellSize = cell
        setFrameSize(ClawdView.canvasSize(cellSize: cell))
        lastRenderKey = ""
        needsDisplay = true
    }
}
