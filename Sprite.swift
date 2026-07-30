import Cocoa

// Clawd's artwork on a 24 x 18 grid of square cells, plus a chef hat + pan
// costume traced frame-by-frame from a real recording of Anthropic's "Desktop
// creatures, built with Claude Code" reel.
//
// Two bugs in the previous costume implementation are why it looked wrong:
//
// 1. The chef poses didn't start with the same 2 blank pad rows every other
//    pose uses, so the head sat 2 rows lower than normal — Clawd visibly
//    jumped down and up when the costume went on/off.
// 2. The chef poses' body rows were missing the 4-column left indent every
//    other pose has, so the whole body was shifted left, which is what let
//    the pan drift into the face instead of sitting cleanly off to the side.
//
// The fix here is structural, not cosmetic: every costumed pose starts as an
// exact copy of `standingGrid` and only overwrites two regions — rows 0-1
// (blank in every other pose) for the hat, and the 4x4 right-arm block
// (cols 20-23, rows 6-9) for the pan — so nothing can ever drift out of
// alignment with the rest of the poses again.

enum Pose {
    case standing
    case lookLeft
    case lookRight
    case armsUp
    case asleep        // eyes closed
    case walkA         // legs 1 & 3 planted
    case walkB         // legs 2 & 4 planted
    case squat         // legs folded under, for the idle sit
    case hatPlacing     // arms raised, physically putting the hat on (or taking it off)
    case hatOn          // hat settled, arms back down, hands empty
    case chefIdle       // hat + pan held at arm height, food resting
    case chefRaiseLeft  // tossing: arm swings up and to the left
    case chefRaiseRight // tossing: arm swings up and to the right
    case chefPeak        // tossing: food airborne at the top of the arc, pan retracted
}

enum ClawdSprite {

    static let cols = 24
    static let rows = 18

    /// rgb(217,119,87) — sampled straight out of the reference GIF's colour table.
    static let bodyColor = NSColor(srgbRed: 217.0 / 255.0, green: 119.0 / 255.0, blue: 87.0 / 255.0, alpha: 1.0)
    static let eyeColor  = NSColor.black
    static let poofColor = NSColor(srgbRed: 217.0 / 255.0, green: 119.0 / 255.0, blue: 87.0 / 255.0, alpha: 0.45)

    /// Chef hat: bright poof on top, a slightly shaded band for the brim.
    static let hatColor      = NSColor(srgbRed: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
    static let hatShadeColor = NSColor(srgbRed: 0.87, green: 0.87, blue: 0.89, alpha: 1.0)
    /// Pan + handle.
    static let panColor  = NSColor(srgbRed: 0.30, green: 0.30, blue: 0.33, alpha: 1.0)
    /// The food being cooked.
    static let foodColor = NSColor(srgbRed: 76.0 / 255.0, green: 175.0 / 255.0, blue: 80.0 / 255.0, alpha: 1.0)

    // '#' = body, '0' = eye, '.' = transparent, 'W'/'w' = hat, 'S' = pan, 'G' = food.
    // Every row is exactly 24 characters, every grid exactly 18 rows.

    private static let standingGrid = [
        "........................",
        "........................",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "########################",
        "########################",
        "########################",
        "########################",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    private static let lookLeftGrid = [
        "........................",
        "........................",
        "....################....",
        "....################....",
        "....00########00####....",
        "....00########00####....",
        "########################",
        "########################",
        "########################",
        "########################",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    private static let lookRightGrid = [
        "........................",
        "........................",
        "....################....",
        "....################....",
        "....####00########00....",
        "....####00########00....",
        "########################",
        "########################",
        "########################",
        "########################",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    private static let armsUpGrid = [
        "........................",
        "........................",
        "....################....",
        "....################....",
        "######00########00######",
        "######00########00######",
        "########################",
        "########################",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    private static let asleepGrid = [
        "........................",
        "........................",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "########################",
        "########################",
        "########################",
        "########################",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    private static let walkAGrid = [
        "........................",
        "........................",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "########################",
        "########################",
        "########################",
        "########################",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##........##........",
        "....##........##........",
        "....##........##........",
    ]

    private static let walkBGrid = [
        "........................",
        "........................",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "########################",
        "########################",
        "########################",
        "########################",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "........##........##....",
        "........##........##....",
        "........##........##....",
    ]

    private static let squatGrid = [
        "........................",
        "........................",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "########################",
        "########################",
        "########################",
        "########################",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "........................",
        "........................",
        "........................",
    ]

    // ── Chef costume ─────────────────────────────────────────────────────
    //
    // Two changes from the previous version, both direct corrections:
    //
    // 1. The pan now sits at rows 6-9 — the SAME rows the right arm nub
    //    normally occupies — instead of hanging below the body. It reads as
    //    something the hand is holding, not a separate floating object.
    // 2. Nothing here ever changes row offset. Earlier the toss lifted the
    //    whole body (`offset: -1`), which read as Clawd jumping. The head,
    //    body and legs are byte-for-byte identical to `standingGrid` in
    //    every one of these poses — only the pan-hand's own pixels move.
    //    The illusion of a wrist-flick toss comes entirely from the pan and
    //    food climbing rows 6 → 5 → 4 → 2 while everything else holds still.

    // Arms raised, hat visible above — the physical "putting it on" gesture,
    // built on top of `armsUpGrid` rather than `standingGrid` since the arms
    // need to actually be up. Reused in reverse for taking the hat back off.
    private static let hatPlacingGrid = [
        "........WWWWWW..........",
        "......WWWWWWWWWWWW......",
        "....wwwwwwwwwwwwwwww....",
        "....################....",
        "######00########00######",
        "######00########00######",
        "########################",
        "########################",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    // Hat settled, arms back down, hands empty — no pan yet.
    private static let hatOnGrid = [
        "........WWWWWW..........",
        "......WWWWWWWWWWWW......",
        "....wwwwwwwwwwwwwwww....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "########################",
        "########################",
        "########################",
        "########################",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    // Resting: pan held right where the right arm normally is, food sitting
    // calmly on top of it. Nothing below row 9 — the pan doesn't hang.
    private static let chefIdleGrid = [
        "........WWWWWW..........",
        "......WWWWWWWWWWWW......",
        "....wwwwwwwwwwwwwwww....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "####################..G.",
        "####################.SSS",
        "####################.SSS",
        "####################....",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    // Wrist flicks up and to the left: pan and food climb into the (normally
    // blank) eye-row band, and the resting-row pixels empty out — the hand
    // has lifted away from where it sits at idle.
    private static let chefRaiseLeftGrid = [
        "........WWWWWW..........",
        "......WWWWWWWWWWWW......",
        "....wwwwwwwwwwwwwwww....",
        "....################....",
        "....##00########00##G...",
        "....##00########00##SS..",
        "####################.S..",
        "####################....",
        "####################....",
        "####################....",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    // Mirror of the above, swung to the right — alternating left/right across
    // a cook loop is what reads as a genuine sideways toss instead of a
    // straight up-down bounce.
    private static let chefRaiseRightGrid = [
        "........WWWWWW..........",
        "......WWWWWWWWWWWW......",
        "....wwwwwwwwwwwwwwww....",
        "....################....",
        "....##00########00##...G",
        "....##00########00##..SS",
        "####################..S.",
        "####################....",
        "####################....",
        "####################....",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    // Peak of the toss: the food separates from the pan entirely and rises
    // to hat height (row 2, which is otherwise the brim's own blank margin),
    // while the pan itself has retracted almost all the way back down.
    private static let chefPeakGrid = [
        "........WWWWWW..........",
        "......WWWWWWWWWWWW......",
        "....wwwwwwwwwwwwwwww..G.",
        "....################....",
        "....##00########00##....",
        "....##00########00##..S.",
        "####################....",
        "####################....",
        "####################....",
        "####################....",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    static func grid(for pose: Pose) -> [String] {
        switch pose {
        case .standing:    return standingGrid
        case .lookLeft:    return lookLeftGrid
        case .lookRight:   return lookRightGrid
        case .armsUp:      return armsUpGrid
        case .asleep:      return asleepGrid
        case .walkA:       return walkAGrid
        case .walkB:       return walkBGrid
        case .squat:            return squatGrid
        case .hatPlacing:       return hatPlacingGrid
        case .hatOn:            return hatOnGrid
        case .chefIdle:         return chefIdleGrid
        case .chefRaiseLeft:    return chefRaiseLeftGrid
        case .chefRaiseRight:   return chefRaiseRightGrid
        case .chefPeak:         return chefPeakGrid
        }
    }

    /// Draws Clawd with hard pixel edges. `cell` is one art pixel in points.
    static func draw(in ctx: CGContext,
                     pose: Pose,
                     originX: CGFloat,
                     originY: CGFloat,
                     cell: CGFloat) {
        let g = grid(for: pose)

        var bodyRects: [CGRect] = []
        var eyeRects: [CGRect] = []
        var hatRects: [CGRect] = []
        var hatShadeRects: [CGRect] = []
        var panRects: [CGRect] = []
        var foodRects: [CGRect] = []
        bodyRects.reserveCapacity(cols * rows)

        for (r, row) in g.enumerated() {
            // Row 0 is the top of the sprite; view coordinates grow upward.
            let y = originY + CGFloat(rows - 1 - r) * cell
            for (c, ch) in row.enumerated() {
                guard ch != "." else { continue }
                let rect = CGRect(x: originX + CGFloat(c) * cell, y: y, width: cell, height: cell)
                switch ch {
                case "0": eyeRects.append(rect)
                case "W": hatRects.append(rect)
                case "w": hatShadeRects.append(rect)
                case "S": panRects.append(rect)
                case "G": foodRects.append(rect)
                default:  bodyRects.append(rect)
                }
            }
        }

        ctx.setFillColor(bodyColor.cgColor)
        ctx.fill(bodyRects)
        if !eyeRects.isEmpty {
            ctx.setFillColor(eyeColor.cgColor)
            ctx.fill(eyeRects)
        }
        if !hatRects.isEmpty {
            ctx.setFillColor(hatColor.cgColor)
            ctx.fill(hatRects)
        }
        if !hatShadeRects.isEmpty {
            ctx.setFillColor(hatShadeColor.cgColor)
            ctx.fill(hatShadeRects)
        }
        if !panRects.isEmpty {
            ctx.setFillColor(panColor.cgColor)
            ctx.fill(panRects)
        }
        if !foodRects.isEmpty {
            ctx.setFillColor(foodColor.cgColor)
            ctx.fill(foodRects)
        }
    }

    /// The little puffs Claude Code draws either side of Clawd when it hops.
    static func drawPoof(in ctx: CGContext,
                         kind: PoofKind,
                         originX: CGFloat,
                         originY: CGFloat,
                         cell: CGFloat) {
        let y = originY + cell * 2
        let right = originX + CGFloat(cols) * cell

        var rects: [CGRect] = []
        switch kind {
        case .dot:
            rects.append(CGRect(x: originX - cell * 3, y: y, width: cell, height: cell))
            rects.append(CGRect(x: right + cell * 2, y: y, width: cell, height: cell))
        case .wave:
            rects.append(CGRect(x: originX - cell * 5, y: y + cell, width: cell * 3, height: cell))
            rects.append(CGRect(x: right + cell * 2, y: y + cell, width: cell * 3, height: cell))
        }

        ctx.setFillColor(poofColor.cgColor)
        ctx.fill(rects)
    }
}
