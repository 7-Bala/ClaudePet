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

/// Animation table including canonical Claude Code moves, Chef Cooking sequences,
/// and the Checkered Victory Flag animation from Codrops GIF.
enum Sequences {

    static let frameInterval: TimeInterval = 0.060

    private static func hold(_ pose: Pose, _ count: Int, offset: CGFloat = 0) -> [Frame] {
        (0..<count).map { _ in Frame(pose: pose, offset: offset) }
    }

    private static func puff() -> [Frame] {
        [Frame(pose: .standing, offset: 2, poof: .dot),
         Frame(pose: .standing, offset: 2, poof: .wave)]
    }

    // MARK: Canonical — match Claude Code frame for frame

    static let look: [Frame] =
        hold(.lookRight, 5) + hold(.lookLeft, 5) + hold(.standing, 1)

    static let jump: [Frame] =
        puff() + hold(.armsUp, 3) + hold(.standing, 1) +
        puff() + hold(.armsUp, 3) + hold(.standing, 1)

    // MARK: Checkered Victory Flag (Task Finished — Codrops GIF Animation) 🏁
    //
    // From the reference GIF the mascot:
    //  1. Gently bounces (offset 0 → -1 → 0) while alternating flag wave A / B
    //  2. Bounces ~4 times total, smooth and steady
    //  3. Ends by returning to standing
    //
    // No extreme offsets (-3, etc.) — the GIF shows only a gentle 1-cell bounce.

    static let flagVictory: [Frame] =
        // Entrance: small poof then start waving
        hold(.standing, 2) +
        // Wave cycle 1: gentle bounce up
        hold(.flagHoldA, 5) +
        hold(.flagHoldB, 5, offset: -1) +
        // Wave cycle 2: bounce back
        hold(.flagHoldA, 5) +
        hold(.flagHoldB, 5, offset: -1) +
        // Wave cycle 3
        hold(.flagHoldA, 5) +
        hold(.flagHoldB, 5, offset: -1) +
        // Wave cycle 4: final wave
        hold(.flagHoldA, 5) +
        hold(.flagHoldB, 5, offset: -1) +
        // Settle back
        hold(.flagHoldA, 4) +
        hold(.standing, 3)

    /// Played when a task completes
    static let celebrate: [Frame] = flagVictory

    static let spin: [Frame] =
        hold(.lookLeft, 2) + hold(.lookRight, 2) + hold(.lookLeft, 2) +
        hold(.armsUp, 3) + hold(.standing, 1)

    static let skip: [Frame] =
        hold(.standing, 1, offset: 2) + hold(.armsUp, 2) + hold(.standing, 1) +
        hold(.standing, 1, offset: 2) + hold(.armsUp, 2) + hold(.standing, 1) +
        hold(.standing, 1, offset: 2) + hold(.armsUp, 2) + puff() +
        hold(.standing, 1)

    static let skipDuration: TimeInterval = TimeInterval(skip.count) * frameInterval

    // MARK: Chef & Cooking Animations 👨‍🍳🔥

    static let chefCooking: [Frame] =
        hold(.chefStanding, 4) +
        hold(.chefCookingA, 4, offset: -1) +
        hold(.chefCookingB, 4) +
        hold(.chefStanding, 3) +
        hold(.chefCookingA, 4, offset: -1) +
        hold(.chefCookingB, 4) +
        hold(.chefJoy, 5) +
        hold(.chefStanding, 3)

    static let chefQuickFlip: [Frame] =
        hold(.chefStanding, 2) +
        hold(.chefCookingA, 3, offset: -1) +
        hold(.chefCookingB, 3) +
        hold(.chefStanding, 2)

    static func clickReaction() -> [Frame] {
        let options = [jump, look, flagVictory, chefCooking]
        return options.randomElement()!
    }

    // MARK: From the crab-walk GIF

    static let walk: [Frame] =
        hold(.walkA, 3, offset: 1) + hold(.standing, 2) +
        hold(.walkB, 3, offset: 1) + hold(.standing, 2)

    // MARK: Idle fidgets — personality

    static let blink: [Frame] =
        hold(.asleep, 2) + hold(.standing, 4)

    static let doubleBlink: [Frame] =
        hold(.asleep, 2) + hold(.standing, 3) + hold(.asleep, 2) + hold(.standing, 4)

    static let lookAround: [Frame] =
        hold(.lookLeft, 7) + hold(.standing, 4) + hold(.lookRight, 7) + hold(.standing, 4)

    static let stretch: [Frame] =
        hold(.armsUp, 3) + hold(.armsUp, 6, offset: -2) + hold(.armsUp, 4, offset: -1) +
        hold(.standing, 3) + hold(.standing, 3, offset: 1) + hold(.standing, 3)

    static let wiggle: [Frame] =
        hold(.lookLeft, 2) + hold(.lookRight, 2) + hold(.lookLeft, 2) +
        hold(.lookRight, 2) + hold(.standing, 3)

    static let shuffle: [Frame] =
        hold(.walkA, 3) + hold(.walkB, 3) + hold(.walkA, 3) + hold(.walkB, 3) + hold(.standing, 2)

    static let sit: [Frame] =
        hold(.standing, 2, offset: 1) + hold(.squat, 20) +
        hold(.squat, 6) + hold(.standing, 2, offset: 1) + hold(.standing, 3)

    static let nod: [Frame] =
        hold(.standing, 3, offset: 1) + hold(.standing, 3) +
        hold(.standing, 3, offset: 1) + hold(.standing, 3)

    static func idleFidget() -> [Frame] {
        [blink, doubleBlink, lookAround, stretch, wiggle, shuffle, sit, nod, flagVictory, chefCooking].randomElement()!
    }

    static func sleepFidget() -> [Frame] {
        [hold(.walkA, 3) + hold(.asleep, 3),
         hold(.asleep, 5, offset: -1) + hold(.asleep, 5),
         hold(.squat, 14) + hold(.asleep, 3)].randomElement()!
    }

    // MARK: Loops

    static let sleeping: [Frame] =
        hold(.asleep, 16) + hold(.asleep, 16, offset: 1)

    static let idle: [Frame] =
        hold(.standing, 14) + hold(.standing, 10, offset: 1)

    static let working: [Frame] =
        hold(.chefStanding, 5) + hold(.chefCookingA, 4, offset: -1) +
        hold(.chefCookingB, 4) + hold(.chefStanding, 3) +
        hold(.lookRight, 3) + hold(.lookLeft, 3) + hold(.chefStanding, 3)

    static let asking: [Frame] =
        hold(.armsUp, 3) + hold(.standing, 2) +
        hold(.armsUp, 3) + hold(.standing, 2) +
        hold(.armsUp, 4, offset: -1) +
        hold(.lookLeft, 4) + hold(.lookRight, 4) +
        hold(.standing, 4)

    // MARK: Reactions

    static let excited: [Frame] =
        hold(.chefStanding, 2) + hold(.chefJoy, 3) + hold(.chefStanding, 2) +
        hold(.lookLeft, 2) + hold(.lookRight, 2) + hold(.standing, 2)

    static let flinch: [Frame] =
        hold(.standing, 2, offset: 2) + hold(.lookLeft, 2) + hold(.lookRight, 2) +
        hold(.standing, 2, offset: 2) + hold(.standing, 2)

    static let bob: [Frame] =
        hold(.standing, 2, offset: 2) + hold(.standing, 2)
}

/// Plays sequences on a fixed 60ms clock.
final class Animator {

    private(set) var current: Frame = Frame()

    private var sequence: [Frame] = Sequences.sleeping
    private var loopSequence: [Frame] = Sequences.sleeping
    private var index = 0
    private var accumulated: TimeInterval = 0
    private var isOneShot = false
    private var lastOneShotStarted = Date.distantPast

    var isBusy: Bool { isOneShot }

    init() {
        current = sequence.first ?? Frame()
    }

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
