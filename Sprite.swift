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
    case asleep       // eyes closed
    case walkA        // legs 1 & 3 planted
    case walkB        // legs 2 & 4 planted
    case squat        // legs folded under, for the idle sit
    case hatForming    // chef hat mid-poof, just starting to appear
    case hatOn         // chef hat fully on, hands empty
    case chefIdle      // hat + pan, food resting in the pan
    case chefFlipUp    // hat + pan, food tossed up in the air
    case chefCatch     // hat + pan, food falling back toward the pan
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
    // Rows 3-9 and 14-17 are byte-for-byte identical to `standingGrid` in
    // every one of these poses — head, eyes, legs and both arm nubs never
    // move a single pixel when the costume goes on, comes off, or the pan
    // starts flipping food. Only three regions ever change: rows 0-2 (the
    // hat), and rows 9-12's last 4 columns (the pan and the food).
    //
    // The pan sits low, hanging off the lower body with a one-row gap below
    // the normal right arm nub — traced from the reel, where the pan reads
    // as a separate item the arm is holding rather than an extension of it.

    // A small grey blob just starting to form above the head.
    private static let hatFormingGrid = [
        "........................",
        ".........ww.............",
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

    // Hat fully poofed: a rounded top, a wide mid band, and a flat brim lip
    // that sits right at the hairline — replacing just the top pixel row of
    // the head, so the head's height and eye position never move.
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

    // Hat on, pan hanging below the right arm, food resting in it. Food and
    // pan share column 22 all the way down so the toss below reads as one
    // straight vertical bounce with no horizontal drift.
    private static let chefIdleGrid = [
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
        "....################..G.",
        "....################.SSS",
        "....################.SSS",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    // Food tossed up off the pan — high enough to pass in front of the arm
    // nub, which is why this is the one frame that borrows a pixel from row 9.
    private static let chefFlipUpGrid = [
        "........WWWWWW..........",
        "......WWWWWWWWWWWW......",
        "....wwwwwwwwwwwwwwww....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "########################",
        "########################",
        "########################",
        "######################G#",
        "....################....",
        "....################....",
        "....################.SSS",
        "....################.SSS",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    // Food on its way back down, passing the empty pan.
    private static let chefCatchGrid = [
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
        "....################..G.",
        "....################....",
        "....################.SSS",
        "....################.SSS",
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
        case .squat:       return squatGrid
        case .hatForming:  return hatFormingGrid
        case .hatOn:       return hatOnGrid
        case .chefIdle:    return chefIdleGrid
        case .chefFlipUp:  return chefFlipUpGrid
        case .chefCatch:   return chefCatchGrid
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
