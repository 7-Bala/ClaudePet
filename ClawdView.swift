import Cocoa

/// Renders Clawd and owns its behaviour: reacting to Claude Code activity,
/// strolling along the Dock, idling with personality & chef cooking attire,
/// and handling user interactions.
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

    private var posX: CGFloat = 0
    private var travelRemaining: CGFloat = 0
    private var travelSpeed: CGFloat = 0
    private var isStrolling = false
    private var nextMoveAt: Date = .distantFuture

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

    private func react(to event: String, tool: String?) {
        switch event {
        case "Stop", "StopFailure":
            animator.play(Sequences.celebrate)
        case "UserPromptSubmit", "SessionStart":
            animator.play(Sequences.excited)
        case "SubagentStart", "SubagentStop":
            animator.play(Sequences.spin)
        case "PostToolUseFailure":
            animator.play(Sequences.flinch)
        case "PreToolUse":
            animator.play(reaction(for: tool))
        default:
            break
        }
    }

    private func reaction(for tool: String?) -> [Frame] {
        switch tool {
        case "Bash", "Edit", "Write", "NotebookEdit":
            return Sequences.chefCooking
        case "Read", "Grep", "Glob", "WebFetch", "WebSearch":
            return Sequences.chefQuickFlip
        case "Task", "Agent":
            return Sequences.spin
        case "AskUserQuestion", "ExitPlanMode":
            return Sequences.asking
        default:
            return Sequences.chefQuickFlip
        }
    }

    private func moodChanged(to newMood: Mood) {
        mood = newMood
        endTravel()
        scheduleNextFidget()
        switch newMood {
        case .asleep:
            animator.setLoop(Sequences.sleeping)
            nextMoveAt = .distantFuture
        case .working:
            animator.setLoop(Sequences.working)
            scheduleNextMove()
        case .waiting:
            animator.setLoop(Sequences.asking)
            nextMoveAt = .distantFuture
        case .celebrating:
            animator.setLoop(Sequences.idle)
            nextMoveAt = .distantFuture
        }
    }

    private func scheduleNextMove() {
        nextMoveAt = Date().addingTimeInterval(Double.random(in: 2.0...5.0))
    }

    private func scheduleNextFidget() {
        nextFidgetAt = Date().addingTimeInterval(Double.random(in: 5.0...13.0))
    }

    private func maybeFidget(now: Date) {
        guard now >= nextFidgetAt, !animator.isBusy, !isHeld,
              elevation == 0, travelRemaining == 0 else { return }
        scheduleNextFidget()

        switch mood {
        case .asleep:
            animator.play(Double.random(in: 0...1) < 0.65
                          ? Sequences.sleepFidget()
                          : Sequences.idleFidget())
        case .working:
            animator.play(Sequences.chefCooking)
        case .waiting, .celebrating:
            break
        }
    }

    // MARK: Tick

    private func tick() {
        let now = Date()
        let dt = min(now.timeIntervalSince(lastTick), 0.1)
        lastTick = now

        monitor.poll()
        if monitor.mood != mood { moodChanged(to: monitor.mood) }

        animator.advance(by: dt)

        updateTravel(dt: CGFloat(dt))
        stepPhysics(dt: CGFloat(dt))
        maybeFidget(now: now)

        if mood == .working, !animator.isBusy, !isHeld, elevation == 0,
           travelRemaining == 0, now >= nextMoveAt {
            Bool.random() ? startStroll() : startSkip()
        }

        if landingCrouch > 0 { landingCrouch -= 1 }
        redrawIfNeeded()
    }

    // MARK: Horizontal movement

    private func horizontalBounds() -> (min: CGFloat, max: CGFloat) {
        guard let window = window, let screen = window.screen ?? NSScreen.main else { return (0, 0) }
        let maxX = max(screen.frame.minX, screen.frame.maxX - window.frame.width)
        return (screen.frame.minX, maxX)
    }

    private func pickDirection(travel: CGFloat) -> CGFloat {
        let bounds = horizontalBounds()
        if posX + travel > bounds.max { return -1 }
        if posX - travel < bounds.min { return 1 }
        return Bool.random() ? 1 : -1
    }

    private func startStroll() {
        let distance = CGFloat.random(in: 50...150)
        travelRemaining = distance * pickDirection(travel: distance)
        travelSpeed = 34
        isStrolling = true
        animator.setLoop(Sequences.walk)
        scheduleNextMove()
    }

    private func startSkip() {
        let distance = 10 * cellSize
        travelRemaining = distance * pickDirection(travel: distance)
        travelSpeed = distance / CGFloat(Sequences.skipDuration)
        isStrolling = false
        animator.play(Sequences.skip)
        scheduleNextMove()
    }

    private func updateTravel(dt: CGFloat) {
        guard travelRemaining != 0 else { return }
        if isHeld || elevation > 0 { endTravel(); return }

        let step = travelSpeed * dt * (travelRemaining < 0 ? -1 : 1)
        let applied = abs(step) >= abs(travelRemaining) ? travelRemaining : step
        posX += applied
        travelRemaining -= applied

        let bounds = horizontalBounds()
        if posX <= bounds.min || posX >= bounds.max { travelRemaining = 0 }
        applyPosition()

        if travelRemaining == 0 { endTravel() }
    }

    private func endTravel() {
        travelRemaining = 0
        if isStrolling {
            isStrolling = false
            animator.setLoop(mood == .working ? Sequences.working : Sequences.sleeping)
        }
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
        endTravel()
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
        let cookItem = NSMenuItem(title: "Cook Dish 👨‍🍳🔥", action: #selector(triggerChefCooking), keyEquivalent: "")
        cookItem.target = self
        menu.addItem(cookItem)

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

    @objc private func triggerChefCooking() {
        animator.play(Sequences.chefCooking, minimumGap: 0)
    }

    private func statusLine() -> String {
        switch mood {
        case .asleep:      return "Sleeping"
        case .working:     return "Claude is cooking..."
        case .waiting:     return "Claude needs you"
        case .celebrating: return "Just finished cooking!"
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
