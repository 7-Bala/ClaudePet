import Cocoa

// Clawd's artwork on a 24 x 15 grid of square cells.
//
// The proportions come from Anthropic's own `Clawd-CrabWalking.gif`
// (claude.ai/images/clawd/core/), which draws the creature on a 12 x 8 grid at
// 100 device pixels per cell. This is that layout at double resolution, which
// buys two things the 12-wide version could not have:
//
//   * legs one cell wide instead of two, so they read as four distinct points
//     rather than merging into a single block, and
//   * eyes that stay square (2x2) with a clear band of body above them.
//
// Everything is square — do not reintroduce the terminal's 1:2 pixel aspect.

enum Pose {
    case standing
    case lookLeft
    case lookRight
    case armsUp
    case asleep     // eyes closed
    case walkA      // right pair lifted
    case walkB      // left pair lifted
    case squat      // legs folded under, for the idle sit
}

enum ClawdSprite {

    static let cols = 24
    static let rows = 15

    /// rgb(217,119,87) — sampled straight out of the reference GIF's colour table.
    static let bodyColor = NSColor(srgbRed: 217.0 / 255.0, green: 119.0 / 255.0, blue: 87.0 / 255.0, alpha: 1.0)
    static let eyeColor  = NSColor.black
    static let poofColor = NSColor(srgbRed: 217.0 / 255.0, green: 119.0 / 255.0, blue: 87.0 / 255.0, alpha: 0.45)

    // '#' = body, '0' = eye, '.' = transparent. Every row is exactly 24 characters.
    //
    // Body block spans cols 4-19 of rows 0-11. Arms are the full 24-wide band on
    // rows 4-7. Feet are four two-cell-wide, three-cell-tall blocks at cols 5, 8,
    // 15 and 18 — two close pairs with a wide centre gap. They are deliberately
    // compact and chunky: never long, thin stick legs. Eyes are 2x2 at rows 2-3.

    private static let standingGrid = [
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
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
    ]

    // Gaze shifts two cells within the face; the eyes never touch the top edge.
    private static let lookLeftGrid = [
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
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
    ]

    private static let lookRightGrid = [
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
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
    ]

    // Arms lift two rows, from rows 4-7 up to rows 2-5.
    private static let armsUpGrid = [
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
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
    ]

    private static let asleepGrid = [
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
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
    ]

    // The stride from the crab-walk GIF: one pair planted, the other lifted clear.
    private static let walkAGrid = [
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
        ".....##.##.....##.##....",
        ".....##.##..............",
        ".....##.##..............",
    ]

    private static let walkBGrid = [
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
        ".....##.##.....##.##....",
        "...............##.##....",
        "...............##.##....",
    ]

    /// Legs folded right up — Clawd sitting down during a long idle.
    private static let squatGrid = [
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
        ".....##.##.....##.##....",
        "........................",
        "........................",
    ]

    static func grid(for pose: Pose) -> [String] {
        switch pose {
        case .standing:  return standingGrid
        case .lookLeft:  return lookLeftGrid
        case .lookRight: return lookRightGrid
        case .armsUp:    return armsUpGrid
        case .asleep:    return asleepGrid
        case .walkA:     return walkAGrid
        case .walkB:     return walkBGrid
        case .squat:     return squatGrid
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
        bodyRects.reserveCapacity(cols * rows)

        for (r, row) in g.enumerated() {
            // Row 0 is the top of the sprite; view coordinates grow upward.
            let y = originY + CGFloat(rows - 1 - r) * cell
            for (c, ch) in row.enumerated() {
                guard ch != "." else { continue }
                let rect = CGRect(x: originX + CGFloat(c) * cell, y: y, width: cell, height: cell)
                if ch == "0" { eyeRects.append(rect) } else { bodyRects.append(rect) }
            }
        }

        ctx.setFillColor(bodyColor.cgColor)
        ctx.fill(bodyRects)
        if !eyeRects.isEmpty {
            ctx.setFillColor(eyeColor.cgColor)
            ctx.fill(eyeRects)
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
