import Cocoa

// Clawd's artwork on a 24 x 18 grid of square cells.
//
// Grid supports standard Clawd poses as well as Chef attire & cooking animations
// inspired by the Claude Code "Desktop creatures, built with Claude Code" reel.

enum Pose {
    case standing
    case lookLeft
    case lookRight
    case armsUp
    case asleep         // eyes closed
    case walkA          // right pair lifted
    case walkB          // left pair lifted
    case squat          // legs folded under, for the idle sit
    case chefStanding   // wearing chef hat with pan & spatula
    case chefCookingA   // flipping food into the air with steam
    case chefCookingB   // catching food in pan with sizzle
    case chefJoy        // chef arms up celebrating dish
}

enum ClawdSprite {

    static let cols = 24
    static let rows = 18

    /// Color palette
    static let bodyColor    = NSColor(srgbRed: 217.0 / 255.0, green: 119.0 / 255.0, blue: 87.0 / 255.0, alpha: 1.0)
    static let eyeColor     = NSColor.black
    static let poofColor    = NSColor(srgbRed: 217.0 / 255.0, green: 119.0 / 255.0, blue: 87.0 / 255.0, alpha: 0.45)
    static let hatColor     = NSColor(srgbRed: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
    static let hatBandColor = NSColor(srgbRed: 0.82, green: 0.82, blue: 0.85, alpha: 1.0)
    static let metalColor   = NSColor(srgbRed: 0.35, green: 0.35, blue: 0.40, alpha: 1.0)
    static let foodColor    = NSColor(srgbRed: 1.0,  green: 0.72, blue: 0.20, alpha: 1.0)
    static let steamColor   = NSColor(srgbRed: 1.0,  green: 1.0,  blue: 1.0,  alpha: 0.65)

    private static let padRow = "........................"

    // '#' = body, '0' = eye, 'W' = chef hat, 'B' = hat band, 'S' = pan/spatula, 'F' = food, 'm' = steam, '.' = transparent

    private static let standingGrid = [
        padRow, padRow, padRow,
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

    private static let lookLeftGrid = [
        padRow, padRow, padRow,
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
        padRow, padRow, padRow,
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

    private static let armsUpGrid = [
        padRow, padRow, padRow,
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
        padRow, padRow, padRow,
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

    private static let walkAGrid = [
        padRow, padRow, padRow,
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
        padRow, padRow, padRow,
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

    private static let squatGrid = [
        padRow, padRow, padRow,
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

    // MARK: Chef Poses (Attire & Cooking Animation)

    private static let chefStandingGrid = [
        "......WWWWWWWWWW........",
        ".....WWWWWWWWWWWW.......",
        ".......BBBBBBBB.........",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "########################",
        "########################",
        "##################SSS...",
        "#################SSSS...",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
    ]

    private static let chefCookingAGrid = [
        "......WWWWWWWWWW...FF...",  // Food flipped into air!
        ".....WWWWWWWWWWWW..mm...",  // Steam
        ".......BBBBBBBB.........",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "########################",
        "##################SSSS..",  // Pan flipped up
        "#################SSSS...",
        "#################SSSS...",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
    ]

    private static let chefCookingBGrid = [
        "......WWWWWWWWWW........",
        ".....WWWWWWWWWWWW.......",
        ".......BBBBBBBB.........",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "##################FF....",  // Food back in pan!
        "##################mm....",  // Sizzle steam
        "#################SSSS...",  // Pan
        "#################SSSS...",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
    ]

    private static let chefJoyGrid = [
        "......WWWWWWWWWW........",
        ".....WWWWWWWWWWWW.......",
        ".......BBBBBBBB.........",
        "....################....",
        "....################....",
        "######00########00######",
        "######00########00######",
        "########################",
        "##################FF....",
        "##################mm....",
        "....################....",
        "....################....",
        "....################....",
        "....################....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
        ".....##.##.....##.##....",
    ]

    static func grid(for pose: Pose) -> [String] {
        switch pose {
        case .standing:     return standingGrid
        case .lookLeft:     return lookLeftGrid
        case .lookRight:    return lookRightGrid
        case .armsUp:       return armsUpGrid
        case .asleep:       return asleepGrid
        case .walkA:        return walkAGrid
        case .walkB:        return walkBGrid
        case .squat:        return squatGrid
        case .chefStanding: return chefStandingGrid
        case .chefCookingA:  return chefCookingAGrid
        case .chefCookingB:  return chefCookingBGrid
        case .chefJoy:       return chefJoyGrid
        }
    }

    /// Draws Clawd with hard pixel edges.
    static func draw(in ctx: CGContext,
                     pose: Pose,
                     originX: CGFloat,
                     originY: CGFloat,
                     cell: CGFloat) {
        let g = grid(for: pose)

        var bodyRects: [CGRect]     = []
        var eyeRects: [CGRect]      = []
        var hatRects: [CGRect]      = []
        var hatBandRects: [CGRect]  = []
        var metalRects: [CGRect]    = []
        var foodRects: [CGRect]     = []
        var steamRects: [CGRect]    = []

        for (r, row) in g.enumerated() {
            let y = originY + CGFloat(rows - 1 - r) * cell
            for (c, ch) in row.enumerated() {
                guard ch != "." else { continue }
                let rect = CGRect(x: originX + CGFloat(c) * cell, y: y, width: cell, height: cell)
                switch ch {
                case "0": eyeRects.append(rect)
                case "W": hatRects.append(rect)
                case "B": hatBandRects.append(rect)
                case "S": metalRects.append(rect)
                case "F": foodRects.append(rect)
                case "m": steamRects.append(rect)
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

        if !hatBandRects.isEmpty {
            ctx.setFillColor(hatBandColor.cgColor)
            ctx.fill(hatBandRects)
        }

        if !metalRects.isEmpty {
            ctx.setFillColor(metalColor.cgColor)
            ctx.fill(metalRects)
        }

        if !foodRects.isEmpty {
            ctx.setFillColor(foodColor.cgColor)
            ctx.fill(foodRects)
        }

        if !steamRects.isEmpty {
            ctx.setFillColor(steamColor.cgColor)
            ctx.fill(steamRects)
        }
    }

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
