import AppKit
import Foundation

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
let imageDirectory = root.appendingPathComponent("docs/images", isDirectory: true)
let iconURL = root.appendingPathComponent("Resources/TokenBar.iconset/icon_512x512@2x.png")
let popoverURL = imageDirectory.appendingPathComponent("tokenbar-popover.png")
let outputURL = imageDirectory.appendingPathComponent("social-preview.png")

guard let icon = NSImage(contentsOf: iconURL),
      let popover = NSImage(contentsOf: popoverURL)
else {
    fputs("Missing TokenBar icon or popover screenshot.\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: imageDirectory,
    withIntermediateDirectories: true)

let width = 1280
let height = 640
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0),
    let context = NSGraphicsContext(bitmapImageRep: bitmap)
else {
    fputs("Unable to create marketing image context.\n", stderr)
    exit(1)
}

func roundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func drawText(
    _ text: String,
    in rect: NSRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment = .left)
{
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byClipping
    (text as NSString).draw(
        in: rect,
        withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ])
}

func drawBadge(_ text: String, x: CGFloat, width: CGFloat) {
    let rect = NSRect(x: x, y: 116, width: width, height: 35)
    roundedRect(
        rect,
        radius: 17.5,
        color: NSColor.white.withAlphaComponent(0.10))
    drawText(
        text,
        in: NSRect(x: x, y: 124, width: width, height: 20),
        font: .systemFont(ofSize: 14, weight: .medium),
        color: NSColor.white.withAlphaComponent(0.88),
        alignment: .center)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high

let canvas = NSRect(x: 0, y: 0, width: width, height: height)
let background = NSGradient(colors: [
    NSColor(calibratedRed: 0.045, green: 0.075, blue: 0.14, alpha: 1),
    NSColor(calibratedRed: 0.07, green: 0.19, blue: 0.36, alpha: 1),
])!
background.draw(in: canvas, angle: 12)

roundedRect(
    NSRect(x: 760, y: -150, width: 610, height: 860),
    radius: 190,
    color: NSColor(calibratedRed: 0.14, green: 0.49, blue: 0.95, alpha: 0.10))
roundedRect(
    NSRect(x: -220, y: 420, width: 660, height: 370),
    radius: 180,
    color: NSColor(calibratedRed: 0.31, green: 0.92, blue: 0.90, alpha: 0.06))

icon.draw(
    in: NSRect(x: 76, y: 461, width: 96, height: 96),
    from: .zero,
    operation: .sourceOver,
    fraction: 1)
drawText(
    "TokenBar for Codex",
    in: NSRect(x: 194, y: 505, width: 510, height: 52),
    font: .systemFont(ofSize: 40, weight: .bold),
    color: .white)
drawText(
    "Live token usage, right in your menu bar.",
    in: NSRect(x: 79, y: 384, width: 620, height: 42),
    font: .systemFont(ofSize: 26, weight: .medium),
    color: NSColor.white.withAlphaComponent(0.92))
drawText(
    "Focused, native and private. Current task and quota at a glance.",
    in: NSRect(x: 80, y: 300, width: 600, height: 72),
    font: .systemFont(ofSize: 17, weight: .regular),
    color: NSColor.white.withAlphaComponent(0.66))

roundedRect(
    NSRect(x: 80, y: 186, width: 222, height: 82),
    radius: 18,
    color: NSColor(calibratedWhite: 0.02, alpha: 0.32))
drawText(
    "42.7K",
    in: NSRect(x: 99, y: 219, width: 118, height: 35),
    font: .monospacedDigitSystemFont(ofSize: 27, weight: .bold),
    color: .white)
drawText(
    "72%",
    in: NSRect(x: 215, y: 221, width: 66, height: 30),
    font: .monospacedDigitSystemFont(ofSize: 21, weight: .semibold),
    color: NSColor(calibratedRed: 0.46, green: 0.93, blue: 0.91, alpha: 1))
drawText(
    "MENU BAR",
    in: NSRect(x: 100, y: 198, width: 181, height: 16),
    font: .systemFont(ofSize: 10, weight: .semibold),
    color: NSColor.white.withAlphaComponent(0.48))

drawBadge("Native AppKit", x: 80, width: 126)
drawBadge("Apple Silicon", x: 218, width: 132)
drawBadge("Local only", x: 362, width: 102)

drawText(
    "Open source  •  No telemetry  •  Near-zero idle CPU",
    in: NSRect(x: 80, y: 62, width: 620, height: 25),
    font: .systemFont(ofSize: 14, weight: .medium),
    color: NSColor.white.withAlphaComponent(0.52))

popover.draw(
    in: NSRect(x: 795, y: 38, width: 408, height: 500),
    from: NSRect(origin: .zero, size: popover.size),
    operation: .sourceOver,
    fraction: 1)

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode marketing image.\n", stderr)
    exit(1)
}
try png.write(to: outputURL, options: .atomic)
print(outputURL.path)
