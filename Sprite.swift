import Cocoa

// Clawd's artwork on a 24 x 18 grid of square cells.
//
// Exactly reproduces Anthropic's "Welcome, Claw'd" pixel grid:
// 4-cell left arm (cols 0-3), 16-cell main body (cols 4-19), 4-cell right arm (cols 20-23),
// and 4 straight legs flush with the outer body edges ("....##..##....##..##....").

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
    static let foodColor     = NSColor(srgbRed: 76.0 / 255.0,  green: 175.0 / 255.0, blue: 80.0 / 255.0, alpha: 1.0) // Bright Green
    static let steamColor    = NSColor(srgbRed: 156.0 / 255.0, green: 204.0 / 255.0, blue: 101.0 / 255.0, alpha: 0.8)

    private static let padRow = "........................"

    // '#' = body, '0' = eye, 'W' = chef hat white, 'w' = hat shade, 'S' = pan/handle grey, 'G' = green food, 'm' = steam green

    // Exact "Welcome, Claw'd" leg layout: Leg 1 at cols 4-5 (flush left), 2-cell gap (cols 6-7),
    // Leg 2 at cols 8-9, 4-cell center gap (cols 10-13), Leg 3 at cols 14-15, 2-cell gap (cols 16-17),
    // Leg 4 at cols 18-19 (flush right).
    private static let welcomeClawdLegs = [
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##...."
    ]

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

    // MARK: Chef Poses (Exact Welcome Claw'd Legs & Chef Hat)

    private static let chefStandingGrid = [
        "........WWWWWW..........",  // Chef Hat crest
        "......WWWWWWWWWW........",  // Chef Hat puff
        ".....WWWWWWWWWWWW.......",  // Chef Hat body
        ".....WWWWWWWWWWWW.......",  // Chef Hat band
        "....################....",  // Body top
        "....################....",
        "....##00########00##....",  // Eyes
        "....##00########00##....",
        "################...mGG..",  // Arms, body, green food ('G') & steam ('m')
        "################..mGGG..",
        "################SSSSSS..",  // Frying pan ('S')
        "....############.SSSS...",  // Pan handle
        "....################....",
        "....################....",
        "....##..##....##..##....",  // Welcome Claw'd Legs
        "....##..##....##..##....",
        "....##..##....##..##....",
        "....##..##....##..##....",
    ]

    private static let chefCookingAGrid = [
        "........WWWWWW.....GGG..",  // Green food flipped high!
        "......WWWWWWWWWW..mGGG..",  // Green food & steam
        ".....WWWWWWWWWWWW.......",
        ".....WWWWWWWWWWWW.......",
        "....################....",
        "....################....",
        "....##00########00##....",
        "....##00########00##....",
        "################........",
        "################.SSSSSS.",  // Pan tilted up
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
        "################...GGG..",  // Green food back in pan
        "################..mGGG..",  // Sizzle steam
        "################SSSSSS..",  // Pan
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
        "################...GGG..",  // Celebrating dish
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
