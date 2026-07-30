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

    // MARK: Chef costume
    //
    // Two things changed here based on watching it happen: putting the hat
    // on is a real gesture — arms rise (`hatPlacing`, which is `armsUp`'s
    // body with the hat drawn on top) and come back down with the hat
    // settled (`hatOn`) — and the body never moves during a toss. The old
    // version lifted the whole sprite (`offset: -1`) to sell the flip, which
    // read as a jump. Now only the pan-hand's own pixels climb from the
    // resting row up through the eye-row band to hat height and back; the
    // head, body and legs hold perfectly still throughout.
    //
    // These are one-shots meant to be played exactly once at the moment the
    // costume goes on or comes off — see ClawdView's costumeOn tracking.

    static let hatOnTransition: [Frame] =
        hold(.hatPlacing, 6) + hold(.hatOn, 3)

    static let hatOffTransition: [Frame] =
        hold(.hatOn, 2) + hold(.hatPlacing, 6) + hold(.standing, 3)

    /// One toss, swung to the left: pan and food climb from the resting row
    /// up to hat height, hang a moment, then come back down.
    private static let tossLeft: [Frame] =
        hold(.chefIdle, 4) +
        hold(.chefRaiseLeft, 3) +
        hold(.chefPeak, 4) +
        hold(.chefRaiseLeft, 3)

    /// Same toss, mirrored to the right. Alternating the two in the loop
    /// below is what makes it read as a real sideways flip rather than a
    /// straight up-down bounce that would obviously be looping.
    private static let tossRight: [Frame] =
        hold(.chefIdle, 4) +
        hold(.chefRaiseRight, 3) +
        hold(.chefPeak, 4) +
        hold(.chefRaiseRight, 3)

    /// The continuous cooking loop. Assumes the hat and pan are already on —
    /// this is what plays for as long as the pan is out, whether that's one
    /// second or ten minutes, with no fixed length of its own to notice.
    static let cookLoop: [Frame] = tossLeft + tossRight

    /// One toss picked at random, for reactions that shouldn't hijack the
    /// loop for long but also shouldn't always look identical.
    static func cookFlip() -> [Frame] {
        Bool.random() ? tossLeft : tossRight
    }

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
