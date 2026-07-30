import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift make_icon.swift <output-directory>\n", stderr)
    exit(2)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let iconset = outputDirectory.appendingPathComponent("TokenBar.iconset", isDirectory: true)
if FileManager.default.fileExists(atPath: iconset.path) {
    try FileManager.default.removeItem(at: iconset)
}
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let entries: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, pixels) in entries {
    let size = NSSize(width: pixels, height: pixels)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0)
    else {
        throw NSError(domain: "TokenBarIcon", code: 1)
    }
    bitmap.size = size
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "TokenBarIcon", code: 2)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    NSGraphicsContext.current?.imageInterpolation = .high
    let rect = NSRect(origin: .zero, size: size)
    let inset = CGFloat(pixels) * 0.055
    let tile = rect.insetBy(dx: inset, dy: inset)
    let radius = CGFloat(pixels) * 0.22
    let background = NSBezierPath(roundedRect: tile, xRadius: radius, yRadius: radius)
    let gradient = NSGradient(
        colors: [
            NSColor(calibratedRed: 0.12, green: 0.18, blue: 0.31, alpha: 1),
            NSColor(calibratedRed: 0.16, green: 0.42, blue: 0.78, alpha: 1),
        ])!
    gradient.draw(in: background, angle: 55)

    let scale = CGFloat(pixels) / 1024
    let lineWidth = max(1, 52 * scale)
    let tokenPath = NSBezierPath()
    tokenPath.lineCapStyle = .round
    tokenPath.lineJoinStyle = .round
    tokenPath.lineWidth = lineWidth
    tokenPath.move(to: NSPoint(x: 292 * scale, y: 686 * scale))
    tokenPath.line(to: NSPoint(x: 732 * scale, y: 686 * scale))
    tokenPath.move(to: NSPoint(x: 512 * scale, y: 686 * scale))
    tokenPath.line(to: NSPoint(x: 512 * scale, y: 342 * scale))
    NSColor.white.setStroke()
    tokenPath.stroke()

    let pulse = NSBezierPath()
    pulse.lineCapStyle = .round
    pulse.lineJoinStyle = .round
    pulse.lineWidth = max(1, 38 * scale)
    pulse.move(to: NSPoint(x: 278 * scale, y: 276 * scale))
    pulse.line(to: NSPoint(x: 384 * scale, y: 276 * scale))
    pulse.line(to: NSPoint(x: 430 * scale, y: 350 * scale))
    pulse.line(to: NSPoint(x: 486 * scale, y: 202 * scale))
    pulse.line(to: NSPoint(x: 546 * scale, y: 310 * scale))
    pulse.line(to: NSPoint(x: 736 * scale, y: 310 * scale))
    NSColor(calibratedRed: 0.47, green: 0.93, blue: 0.91, alpha: 1).setStroke()
    pulse.stroke()

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "TokenBarIcon", code: 3)
    }
    try png.write(to: iconset.appendingPathComponent(name))
}
