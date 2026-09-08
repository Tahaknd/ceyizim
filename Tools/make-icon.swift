import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF)/255, green: CGFloat((hex >> 8) & 0xFF)/255,
            blue: CGFloat(hex & 0xFF)/255, alpha: a)
}

func heartPath(center: CGPoint, width w: CGFloat) -> CGPath {
    // Heart drawn in a top-down coordinate system.
    let p = CGMutablePath()
    let h = w * 0.92
    let x = center.x, y = center.y - h * 0.05
    let top = y - h/2, bottom = y + h/2
    p.move(to: CGPoint(x: x, y: bottom))
    p.addCurve(to: CGPoint(x: x - w/2, y: top + h*0.3),
               control1: CGPoint(x: x - w*0.55, y: bottom - h*0.35),
               control2: CGPoint(x: x - w/2, y: top + h*0.55))
    p.addArc(center: CGPoint(x: x - w/4, y: top + h*0.3), radius: w/4,
             startAngle: .pi, endAngle: 0, clockwise: false)
    p.addArc(center: CGPoint(x: x + w/4, y: top + h*0.3), radius: w/4,
             startAngle: .pi, endAngle: 0, clockwise: false)
    p.addCurve(to: CGPoint(x: x, y: bottom),
               control1: CGPoint(x: x + w/2, y: top + h*0.55),
               control2: CGPoint(x: x + w*0.55, y: bottom - h*0.35))
    p.closeSubpath()
    return p
}

func sparkle(_ ctx: CGContext, at c: CGPoint, r: CGFloat, color: CGColor) {
    let p = CGMutablePath()
    let inner = r * 0.28
    for i in 0..<8 {
        let angle = CGFloat(i) * .pi / 4 - .pi / 2
        let rad = i % 2 == 0 ? r : inner
        let pt = CGPoint(x: c.x + cos(angle) * rad, y: c.y + sin(angle) * rad)
        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    p.closeSubpath()
    ctx.setFillColor(color)
    ctx.addPath(p); ctx.fillPath()
}

func render(bgTop: CGColor, bgBottom: CGColor, chest: CGColor, chestShade: CGColor,
            heart: CGColor, accent: CGColor, drawShadow: Bool, file: String) {
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    // flip so y grows downwards
    ctx.translateBy(x: 0, y: size); ctx.scaleBy(x: 1, y: -1)

    // Background gradient
    let grad = CGGradient(colorsSpace: cs, colors: [bgTop, bgBottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size, y: size), options: [])

    // Soft glow behind chest
    ctx.saveGState()
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
    ctx.addEllipse(in: CGRect(x: 132, y: 200, width: 760, height: 760)); ctx.fillPath()
    ctx.restoreGState()

    // Chest body
    let bodyRect = CGRect(x: 222, y: 500, width: 580, height: 300)
    let lidRect = CGRect(x: 196, y: 372, width: 632, height: 180)

    if drawShadow {
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.22))
        ctx.setFillColor(chest)
        ctx.addPath(CGPath(roundedRect: bodyRect, cornerWidth: 48, cornerHeight: 48, transform: nil)); ctx.fillPath()
        ctx.restoreGState()
    }
    ctx.setFillColor(chest)
    ctx.addPath(CGPath(roundedRect: bodyRect, cornerWidth: 48, cornerHeight: 48, transform: nil)); ctx.fillPath()

    // Lid (rounded top, flat bottom)
    let lid = CGMutablePath()
    let r: CGFloat = 90
    lid.move(to: CGPoint(x: lidRect.minX, y: lidRect.maxY))
    lid.addLine(to: CGPoint(x: lidRect.minX, y: lidRect.minY + r))
    lid.addArc(tangent1End: CGPoint(x: lidRect.minX, y: lidRect.minY), tangent2End: CGPoint(x: lidRect.minX + r, y: lidRect.minY), radius: r)
    lid.addLine(to: CGPoint(x: lidRect.maxX - r, y: lidRect.minY))
    lid.addArc(tangent1End: CGPoint(x: lidRect.maxX, y: lidRect.minY), tangent2End: CGPoint(x: lidRect.maxX, y: lidRect.minY + r), radius: r)
    lid.addLine(to: CGPoint(x: lidRect.maxX, y: lidRect.maxY))
    lid.closeSubpath()
    ctx.setFillColor(chestShade)
    ctx.addPath(lid); ctx.fillPath()

    // Lid rim
    ctx.setFillColor(chest)
    ctx.addPath(CGPath(roundedRect: CGRect(x: 196, y: 530, width: 632, height: 44), cornerWidth: 22, cornerHeight: 22, transform: nil)); ctx.fillPath()

    // Straps
    ctx.setFillColor(accent)
    for x: CGFloat in [330, 660] {
        ctx.fill(CGRect(x: x, y: 574, width: 34, height: 226))
    }
    // Strap caps on lid
    for x: CGFloat in [330, 660] {
        ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: 372 + 30, width: 34, height: 158), cornerWidth: 8, cornerHeight: 8, transform: nil)); ctx.fillPath()
    }

    // Heart lock
    ctx.setFillColor(heart)
    ctx.addPath(heartPath(center: CGPoint(x: 512, y: 600), width: 150)); ctx.fillPath()

    // Sparkles
    sparkle(ctx, at: CGPoint(x: 810, y: 300), r: 44, color: chest)
    sparkle(ctx, at: CGPoint(x: 236, y: 276), r: 30, color: chest)
    sparkle(ctx, at: CGPoint(x: 870, y: 420), r: 20, color: chest)

    let image = ctx.makeImage()!
    let url = URL(fileURLWithPath: outDir).appendingPathComponent(file)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.path)")
}

// Light
render(bgTop: rgb(0xF2A7BA), bgBottom: rgb(0xC8506F),
       chest: rgb(0xFFF7F2), chestShade: rgb(0xFBE7E0),
       heart: rgb(0xD4667F), accent: rgb(0xE9B7C4), drawShadow: true, file: "AppIcon.png")
// Dark
render(bgTop: rgb(0x2E1C26), bgBottom: rgb(0x140D11),
       chest: rgb(0xE58AA0), chestShade: rgb(0xD1728A),
       heart: rgb(0xFFF1F4), accent: rgb(0xF3B9C7), drawShadow: true, file: "AppIcon-Dark.png")
// Tinted (grayscale on black; system applies the tint)
render(bgTop: rgb(0x000000), bgBottom: rgb(0x000000),
       chest: rgb(0xFFFFFF), chestShade: rgb(0xD9D9D9),
       heart: rgb(0x6E6E6E), accent: rgb(0xBFBFBF), drawShadow: false, file: "AppIcon-Tinted.png")
