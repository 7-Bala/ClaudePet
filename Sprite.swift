import Cocoa

// Clawd's artwork on a 24 x 18 grid of square cells.
//
// Exactly reproduces Anthropic's "Welcome, Claw'd" pixel grid and includes the
// Checkered Victory Flag animation from the Codrops GIF: a tall black pole rising
// from the right shoulder with a 4x3 checkered flag waving at the top, while
// the mascot bounces.

enum Pose {
    case standing
    case lookLeft
    case lookRight
    case armsUp
    case asleep         // eyes closed
    case walkA          // legs 1 & 3 planted
    case walkB          // legs 2 & 4 planted
    case squat          // legs folded under, for idle sit
    case chefStanding   // wearing white chef hat, left arm, pan & spatula with green food
    case chefCookingA   // flipping green food high into the air
    case chefCookingB   // catching green food back in pan
    case chefJoy        // celebrating dish with arms up
    case flagHoldA      // holding checkered flag on tall pole (flag waves left)
    case flagHoldB      // holding checkered flag on tall pole (flag waves right)
}

enum ClawdSprite {

    static let cols = 24
    static let rows = 18

    /// Color palette sampled straight out of the official reference artwork
    static let bodyColor     = NSColor(srgbRed: 217.0 / 255.0, green: 119.0 / 255.0, blue: 87.0 / 255.0, alpha: 1.0)
    static let eyeColor      = NSColor.black
    static let poofColor     = NSColor(srgbRed: 217.0 / 255.0, green: 119.0 / 255.0, blue: 87.0 / 255.0, alpha: 0.45)
    static let hatColor      = NSColor(srgbRed: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
    static let hatShadeColor = NSColor(srgbRed: 0.88, green: 0.88, blue: 0.90, alpha: 1.0)
    static let metalColor    = NSColor(srgbRed: 0.30, green: 0.30, blue: 0.33, alpha: 1.0)
    static let foodColor     = NSColor(srgbRed: 76.0 / 255.0,  green: 175.0 / 255.0, blue: 80.0 / 255.0, alpha: 1.0)
    static let steamColor    = NSColor(srgbRed: 156.0 / 255.0, green: 204.0 / 255.0, blue: 101.0 / 255.0, alpha: 0.8)
    static let poleColor     = NSColor(srgbRed: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)

    private static let padRow = "........................"

    // Character key:
    // '#' = body, '0' = eye, 'W' = white (hat/flag white), 'w' = hat shade,
    // 'S' = pan/handle grey, 'G' = green food, 'm' = steam,
    // 'p' = flag pole (dark), 'k' = flag black square

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Standard Poses
    // ──────────────────────────────────────────────────────────────────────

    private static let standingGrid = [
        padRow, padRow,
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
        padRow, padRow,
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
        padRow, padRow,
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
        padRow, padRow,
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
        padRow, padRow,
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
        padRow, padRow,
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
        padRow, padRow,
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
        padRow, padRow,
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

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Chef Poses
    // ──────────────────────────────────────────────────────────────────────

    private static let chefStandingGrid = [
        "........WWWWWW..........",
        "......WWWWWWWWWW........",
        ".....WWWWWWWWWWWW.......",
        ".....WWWWWWWWWWWW.......",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "################...mGG..",
        "################..mGGG..",
        "################SSSSSS..",
        "....############.SSSS...",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    private static let chefCookingAGrid = [
        "........WWWWWW.....GGG..",
        "......WWWWWWWWWW..mGGG..",
        ".....WWWWWWWWWWWW.......",
        ".....WWWWWWWWWWWW.......",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "################........",
        "################.SSSSSS.",
        "################.SSSSSS.",
        "....############.SSSS...",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    private static let chefCookingBGrid = [
        "........WWWWWW..........",
        "......WWWWWWWWWW........",
        ".....WWWWWWWWWWWW.......",
        ".....WWWWWWWWWWWW.......",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "################...GGG..",
        "################..mGGG..",
        "################SSSSSS..",
        "....############.SSSS...",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    private static let chefJoyGrid = [
        "........WWWWWW..........",
        "......WWWWWWWWWW........",
        ".....WWWWWWWWWWWW.......",
        ".....WWWWWWWWWWWW.......",
        "....################....",
        "######00########00######",
        "######00########00######",
        "################...GGG..",
        "################..mGGG..",
        "................SSSSSS..",
        "....################....",
        "....################....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    // ──────────────────────────────────────────────────────────────────────
    // MARK: Checkered Victory Flag Poses (from Codrops GIF)
    //
    // Matching the reference exactly:
    // - Tall black pole ('p') rises from right shoulder (col 19), 4 cells above head
    // - 4x3 checkered flag ('k' black, 'W' white) attached to top of pole
    // - Flag waves by shifting 1 col left/right between A and B
    // - Body is standard standing shape (no arms out)
    // ──────────────────────────────────────────────────────────────────────

    private static let flagHoldAGrid = [
        "..............kWkWkWp...",  // row 0: 6-wide checkered flag left of pole (wave-A)
        "..............WkWkWkp...",  // row 1: checkered row 2
        "..............kWkWkWp...",  // row 2: checkered row 3
        "..............WkWkWkp...",  // row 3: checkered row 4
        "....................p...",  // row 4: pole above head
        "....................p...",  // row 5: pole above head
        "....################p...",  // row 6: head + pole continuing
        "....################p...",  // row 7: head + pole
        "....##00########00##p...",  // row 8: eyes + pole
        "....##00########00##p...",  // row 9: eyes + pole
        "....################....",  // row 10: body
        "....################....",  // row 11: body
        "....################....",  // row 12: lower body
        "....################....",  // row 13: lower body
        "....##..##....##..##....",  // row 14: legs
        "....##..##....##..##....",  // row 15: legs
        "....##..##....##..##....",  // row 16: legs
        "....##..##....##..##....",  // row 17: legs
    ]

    private static let flagHoldBGrid = [
        "...............kWkWkWp..",  // row 0: 6-wide checkered flag shifted right (wave-B)
        "...............WkWkWkp..",  // row 1: checkered row 2
        "...............kWkWkWp..",  // row 2: checkered row 3
        "...............WkWkWkp..",  // row 3: checkered row 4
        "....................p...",  // row 4: pole above head
        "....................p...",  // row 5: pole above head
        "....################p...",  // row 6: head + pole continuing
        "....################p...",  // row 7: head + pole
        "....##00########00##p...",  // row 8: eyes + pole
        "....##00########00##p...",  // row 9: eyes + pole
        "....################....",  // row 10: body
        "....################....",  // row 11: body
        "....################....",  // row 12: lower body
        "....################....",  // row 13: lower body
        "....##..##....##..##....",  // row 14: legs
        "....##..##....##..##....",  // row 15: legs
        "....##..##....##..##....",  // row 16: legs
        "....##..##....##..##....",  // row 17: legs
    ]

    static func grid(for pose: Pose) -> [String] {
        switch pose {
        case .standing:      return standingGrid
        case .lookLeft:      return lookLeftGrid
        case .lookRight:     return lookRightGrid
        case .armsUp:        return armsUpGrid
        case .asleep:        return asleepGrid
        case .walkA:         return walkAGrid
        case .walkB:         return walkBGrid
        case .squat:         return squatGrid
        case .chefStanding:  return chefStandingGrid
        case .chefCookingA:  return chefCookingAGrid
        case .chefCookingB:  return chefCookingBGrid
        case .chefJoy:       return chefJoyGrid
        case .flagHoldA:     return flagHoldAGrid
        case .flagHoldB:     return flagHoldBGrid
        }
    }

    /// Draws Clawd with crisp pixel edges.
    static func draw(in ctx: CGContext,
                     pose: Pose,
                     originX: CGFloat,
                     originY: CGFloat,
                     cell: CGFloat) {
        let g = grid(for: pose)

        var bodyRects: [CGRect]      = []
        var eyeRects: [CGRect]       = []
        var hatRects: [CGRect]       = []
        var hatShadeRects: [CGRect]  = []
        var metalRects: [CGRect]     = []
        var foodRects: [CGRect]      = []
        var steamRects: [CGRect]     = []
        var poleRects: [CGRect]      = []
        var blackFlagRects: [CGRect] = []

        for (r, row) in g.enumerated() {
            let y = originY + CGFloat(rows - 1 - r) * cell
            for (c, ch) in row.enumerated() {
                guard ch != "." else { continue }
                let rect = CGRect(x: originX + CGFloat(c) * cell, y: y, width: cell, height: cell)
                switch ch {
                case "0": eyeRects.append(rect)
                case "W": hatRects.append(rect)
                case "w": hatShadeRects.append(rect)
                case "S": metalRects.append(rect)
                case "G": foodRects.append(rect)
                case "m": steamRects.append(rect)
                case "p": poleRects.append(rect)
                case "k": blackFlagRects.append(rect)
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

        if !poleRects.isEmpty {
            ctx.setFillColor(poleColor.cgColor)
            ctx.fill(poleRects)
        }

        if !blackFlagRects.isEmpty {
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(blackFlagRects)
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
