import Foundation

enum PoofKind {
    case dot
    case wave
}

/// One 60ms tick of an animation.
struct Frame {
    var pose: Pose = .standing
    /// How far to drop the sprite, in cells. Negative lifts it.
    var offset: CGFloat = 0
    var poof: PoofKind? = nil
}

/// Claude Code's own animation table, reproduced frame for frame, a chef
/// costume sequence, and a set of idle fidgets so Clawd has something to do
/// when nothing is happening.
enum Sequences {

    static let frameInterval: TimeInterval = 0.060

    private static func hold(_ pose: Pose, _ count: Int, offset: CGFloat = 0) -> [Frame] {
        (0..<count).map { _ in Frame(pose: pose, offset: offset) }
    }

    /// The two-frame puff that starts a hop.
    private static func puff() -> [Frame] {
        [Frame(pose: .standing, offset: 2, poof: .dot),
         Frame(pose: .standing, offset: 2, poof: .wave)]
    }

    // MARK: Canonical — these match Claude Code frame for frame

    static let look: [Frame] =
        hold(.lookRight, 5) + hold(.lookLeft, 5) + hold(.standing, 1)

    static let jump: [Frame] =
        puff() + hold(.armsUp, 3) + hold(.standing, 1) +
        puff() + hold(.armsUp, 3) + hold(.standing, 1)

    static let celebrate: [Frame] =
        jump + hold(.standing, 3, offset: 2)

    static let spin: [Frame] =
        hold(.lookLeft, 2) + hold(.lookRight, 2) + hold(.lookLeft, 2) +
        hold(.armsUp, 3) + hold(.standing, 1)

    /// Clicking Clawd in Claude Code plays one of these at random.
    static func clickReaction() -> [Frame] {
        Bool.random() ? jump : look
    }

    // MARK: Chef costume — visual correction pass
    //
    // Putting the hat on is a real gesture — arms rise (`hatPlacing`, which
    // is `armsUp`'s body with the hat drawn on top) and come back down with
    // the hat settled (`hatOn`).
    //
    // The toss itself is built from causally-ordered authored poses rather
    // than a generic up/down bounce: look at the pan, dip in anticipation,
    // flick, food separates, food climbs (tumbling, slowing near the top),
    // holds at the apex, falls (tumbling, accelerating), lands, the pan dips
    // on impact, and only after a beat do the eyes relax forward again. The
    // body's `offset` is 0 in every one of these frames — the only things
    // that move are the arm/pan assembly and the food, exactly as specified.
    //
    // hatOnTransition/hatOffTransition are one-shots meant to play exactly
    // once at the moment the costume goes on or comes off — see ClawdView's
    // costumeOn tracking.

    static let hatOnTransition: [Frame] =
        hold(.hatPlacing, 6) + hold(.hatOn, 3)

    static let hatOffTransition: [Frame] =
        hold(.hatOn, 2) + hold(.hatPlacing, 6) + hold(.standing, 3)

    /// One full toss: hold → anticipate → flick → launch → rise (tumbling,
    /// slowing) → apex (held) → fall (tumbling, accelerating) → catch → dip
    /// → recover → a beat of inspection before the eyes let go of the pan.
    /// Hold counts are deliberately uneven — fast near the pan, slow near
    /// the apex — instead of even spacing, so the motion doesn't read as a
    /// constant-speed loop.
    private static let toss: [Frame] =
        hold(.cookHoldPan, 8) +          // COOK_READY / COOK_LOOK_PAN
        hold(.cookAnticipate, 4) +       // anticipation: wrist dips
        hold(.cookFlick1, 2) +           // wrist rising
        hold(.cookFlick2, 2) +           // strongest flick — hat reacts, food launches
        hold(.cookFoodLeaving, 2) +      // food just separated, adjacent to the pan
        hold(.cookFoodLowAscend, 2) +    // fast
        hold(.cookFoodHighAscend, 3) +   // slowing
        hold(.cookFoodApex, 5) +         // held — the tiny stare
        hold(.cookFoodHighDescend, 3) +  // slow
        hold(.cookFoodLowDescend, 2) +   // faster
        hold(.cookCatch, 2) +            // food adjacent to the rim
        hold(.cookCatchDip, 3) +         // pan + arm dip on impact
        hold(.cookHoldPan, 4)            // recover, then inspect — eyes stay on the pan

    /// Occasionally, between tosses, the eyes actually relax forward for a
    /// moment — "the rare idle moment" — before the next toss begins.
    private static let tossThenRelax: [Frame] = toss + hold(.cookIdleEyes, 3)

    /// The continuous cooking loop. Assumes the hat and pan are already on —
    /// this is what plays for as long as the pan is out, whether that's one
    /// second or ten minutes, with no fixed length of its own to notice.
    static let cookLoop: [Frame] = toss + toss + tossThenRelax

    // MARK: Other tool-shaped activities
    //
    // Only cooking gets the hat treatment — these two are lighter-weight
    // prop swaps with no ceremony, appropriate for the quicker things Claude
    // actually does most of the time: looking something up, or editing a
    // file. Uneven hold counts are deliberate, so two back-to-back loops
    // don't land on an identical beat and read as an obvious repeat.

    /// Reading/researching — a small terminal, cursor blinking irregularly.
    static let readingLoop: [Frame] =
        hold(.terminalOn, 11) + hold(.terminalOff, 5) +
        hold(.terminalOn, 7) + hold(.terminalOff, 4) +
        hold(.terminalOn, 13) + hold(.terminalOff, 5)

    /// Editing — a small keyboard, left hand tapping.
    static let typingLoop: [Frame] =
        hold(.typingA, 6) + hold(.typingB, 2) + hold(.typingA, 4) + hold(.typingB, 2) +
        hold(.typingA, 9) + hold(.typingB, 2) + hold(.typingA, 5) + hold(.typingB, 2)

    /// No specific tool active yet — present, occasionally blinking, no prop.
    /// What plays between UserPromptSubmit and the first tool call.
    static let workingIdle: [Frame] =
        hold(.standing, 20) + hold(.asleep, 2) + hold(.standing, 16)

    // MARK: Idle fidgets — the personality

    static let blink: [Frame] =
        hold(.asleep, 2) + hold(.standing, 4)

    static let doubleBlink: [Frame] =
        hold(.asleep, 2) + hold(.standing, 3) + hold(.asleep, 2) + hold(.standing, 4)

    /// Slow sweep of the room.
    static let lookAround: [Frame] =
        hold(.lookLeft, 7) + hold(.standing, 4) + hold(.lookRight, 7) + hold(.standing, 4)

    /// Rises up on tiptoe with both arms out, holds, then settles.
    static let stretch: [Frame] =
        hold(.armsUp, 3) + hold(.armsUp, 6, offset: -2) + hold(.armsUp, 4, offset: -1) +
        hold(.standing, 3) + hold(.standing, 3, offset: 1) + hold(.standing, 3)

    /// Shivers side to side.
    static let wiggle: [Frame] =
        hold(.lookLeft, 2) + hold(.lookRight, 2) + hold(.lookLeft, 2) +
        hold(.lookRight, 2) + hold(.standing, 3)

    /// Marches on the spot.
    static let shuffle: [Frame] =
        hold(.walkA, 3) + hold(.walkB, 3) + hold(.walkA, 3) + hold(.walkB, 3) + hold(.standing, 2)

    /// Sits down for a moment, then gets back up.
    static let sit: [Frame] =
        hold(.standing, 2, offset: 1) + hold(.squat, 20) +
        hold(.squat, 6) + hold(.standing, 2, offset: 1) + hold(.standing, 3)

    /// A small nod.
    static let nod: [Frame] =
        hold(.standing, 3, offset: 1) + hold(.standing, 3) +
        hold(.standing, 3, offset: 1) + hold(.standing, 3)

    /// Picked at random whenever Clawd has been standing still for a while.
    /// Only used while asleep/idle — never while the pan is out, since the
    /// continuous cook loop already has something happening on screen.
    static func idleFidget() -> [Frame] {
        [blink, doubleBlink, lookAround, stretch, wiggle, shuffle, sit, nod].randomElement()!
    }

    /// Twitches in its sleep.
    static func sleepFidget() -> [Frame] {
        [hold(.walkA, 3) + hold(.asleep, 3),
         hold(.asleep, 5, offset: -1) + hold(.asleep, 5),
         hold(.squat, 14) + hold(.asleep, 3)].randomElement()!
    }

    // MARK: Loops

    /// Barely-there breathing for when nothing is running. ~2s per cycle.
    static let sleeping: [Frame] =
        hold(.asleep, 16) + hold(.asleep, 16, offset: 1)

    /// Awake and waiting, but not working.
    static let idle: [Frame] =
        hold(.standing, 14) + hold(.standing, 10, offset: 1)

    /// Deliberately unlike anything in the working set: Clawd waves both arms,
    /// bounces, then tilts its head at you. Loops until you answer.
    static let asking: [Frame] =
        hold(.armsUp, 3) + hold(.standing, 2) +
        hold(.armsUp, 3) + hold(.standing, 2) +
        hold(.armsUp, 4, offset: -1) +
        hold(.lookLeft, 4) + hold(.lookRight, 4) +
        hold(.standing, 4)

    // MARK: Reactions

    static let flinch: [Frame] =
        hold(.standing, 2, offset: 2) + hold(.lookLeft, 2) + hold(.lookRight, 2) +
        hold(.standing, 2, offset: 2) + hold(.standing, 2)
}

/// Plays sequences on a fixed 60ms clock. A one-shot sequence runs to completion
/// and then falls back to whatever loop is currently set.
final class Animator {

    private(set) var current: Frame = Frame()

    private var sequence: [Frame] = Sequences.sleeping
    private var loopSequence: [Frame] = Sequences.sleeping
    private var index = 0
    private var accumulated: TimeInterval = 0
    private var isOneShot = false
    private var lastOneShotStarted = Date.distantPast

    /// True while a one-shot reaction is still playing.
    var isBusy: Bool { isOneShot }

    init() {
        current = sequence.first ?? Frame()
    }

    /// Sets the background loop. Takes effect once any one-shot finishes.
    func setLoop(_ frames: [Frame]) {
        guard !frames.isEmpty else { return }
        let changed = !framesMatch(loopSequence, frames)
        loopSequence = frames
        if !isOneShot && changed {
            sequence = frames
            index = 0
            accumulated = 0
            current = frames[0]
        }
    }

    /// Interrupts with a one-shot reaction, then returns to the loop.
    ///
    /// Rate-limited: a burst of twenty `Read` calls would otherwise strobe.
    @discardableResult
    func play(_ frames: [Frame], minimumGap: TimeInterval = 0.4) -> Bool {
        guard !frames.isEmpty else { return false }
        if isOneShot { return false }
        guard Date().timeIntervalSince(lastOneShotStarted) >= minimumGap else { return false }

        lastOneShotStarted = Date()
        sequence = frames
        isOneShot = true
        index = 0
        accumulated = 0
        current = frames[0]
        return true
    }

    /// Like `play`, but takes priority over any in-flight one-shot instead of
    /// being dropped by it. Used for the hat on/off transitions, which must
    /// never silently lose a race against an incidental reaction animation.
    func playImmediately(_ frames: [Frame]) {
        guard !frames.isEmpty else { return }
        lastOneShotStarted = Date()
        sequence = frames
        isOneShot = true
        index = 0
        accumulated = 0
        current = frames[0]
    }

    func advance(by dt: TimeInterval) {
        guard !sequence.isEmpty else { return }
        accumulated += dt
        while accumulated >= Sequences.frameInterval {
            accumulated -= Sequences.frameInterval
            index += 1
            if index >= sequence.count {
                if isOneShot {
                    isOneShot = false
                    sequence = loopSequence
                }
                index = 0
            }
        }
        current = sequence[min(index, sequence.count - 1)]
    }

    private func framesMatch(_ a: [Frame], _ b: [Frame]) -> Bool {
        guard a.count == b.count else { return false }
        for (x, y) in zip(a, b) where x.pose != y.pose || x.offset != y.offset {
            return false
        }
        return true
    }
}
