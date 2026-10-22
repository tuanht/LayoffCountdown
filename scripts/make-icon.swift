// Draws the 1024 px app icon master: a skull inside a draining red countdown ring.
// Usage: swift scripts/make-icon.swift <output.png>
// scripts/make-icon.sh resizes it into App/Assets.xcassets/AppIcon.appiconset.

import AppKit

let size = 1024.0
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8,
                    bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// macOS icon grid: 824 px body centred on the 1024 canvas, leaving room for the shadow.
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)
let background = rgb(0x18181B)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: rgb(0x000000, 0.45))
ctx.addPath(bodyPath)
ctx.setFillColor(background)
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(bodyPath)
ctx.clip()
let gradient = CGGradient(colorsSpace: space,
                          colors: [rgb(0x2E2E33), rgb(0x111113)] as CFArray,
                          locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
ctx.restoreGState()

// Countdown ring: a dim track with the remaining time in red, running clockwise from 12 o'clock.
let center = CGPoint(x: 512, y: 512)
let radius = 300.0
let lineWidth = 40.0
let remaining = 0.28
ctx.setLineWidth(lineWidth)
ctx.setLineCap(.round)
ctx.setStrokeColor(rgb(0x3A3A40))
ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.strokePath()

ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 24, color: rgb(0xFF3B30, 0.6))
ctx.setStrokeColor(rgb(0xFF3B30))
ctx.addArc(center: center, radius: radius, startAngle: .pi / 2,
           endAngle: .pi / 2 - .pi * 2 * remaining, clockwise: true)
ctx.strokePath()
ctx.restoreGState()

// Skull. CoreGraphics is y-up, so larger y is higher on the icon; shift down to centre it in the ring.
ctx.translateBy(x: 0, y: -30)
let bone = rgb(0xEDEAE4)
ctx.setFillColor(bone)
ctx.fillEllipse(in: CGRect(x: 512 - 165, y: 455, width: 330, height: 300))
let jaw = CGPath(roundedRect: CGRect(x: 512 - 92, y: 360, width: 184, height: 130),
                 cornerWidth: 34, cornerHeight: 34, transform: nil)
ctx.addPath(jaw)
ctx.fillPath()

let hole = rgb(0x1C1C20)
ctx.setFillColor(hole)
ctx.fillEllipse(in: CGRect(x: 512 - 120, y: 510, width: 92, height: 100))
ctx.fillEllipse(in: CGRect(x: 512 + 28, y: 510, width: 92, height: 100))

ctx.move(to: CGPoint(x: 512, y: 500))
ctx.addLine(to: CGPoint(x: 512 - 24, y: 455))
ctx.addLine(to: CGPoint(x: 512 + 24, y: 455))
ctx.closePath()
ctx.fillPath()

ctx.setStrokeColor(hole)
ctx.setLineWidth(10)
ctx.setLineCap(.round)
for x: CGFloat in [466, 512, 558] {
    ctx.move(to: CGPoint(x: x, y: 378))
    ctx.addLine(to: CGPoint(x: x, y: 425))
}
ctx.strokePath()

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
