#!/usr/bin/env swift
// Generates ClipboardBar's AppIcon.icns (clipboard with green checkmark on a blue tile).
// Usage: swift make_icon.swift <output_dir>
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func drawBackground(gradient: NSGradient, in path: NSBezierPath) {
    gradient.draw(in: path, angle: -70)
}

func makeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.16, green: 0.55, blue: 0.96, alpha: 1.0),
        NSColor(calibratedRed: 0.29, green: 0.35, blue: 0.95, alpha: 1.0)
    ])!
    let bgPath = NSBezierPath(roundedRect: canvas, xRadius: size * 0.22, yRadius: size * 0.22)
    drawBackground(gradient: gradient, in: bgPath)

    let scale: CGFloat = size / 1024.0

    let clipW = 470 * scale
    let clipH = 560 * scale
    let clipX = (size - clipW) / 2
    let clipY = (size - clipH) / 2 + 10 * scale
    let clipRect = NSRect(x: clipX, y: clipY, width: clipW, height: clipH)
    let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: 60 * scale, yRadius: 60 * scale)
    NSColor.white.setFill()
    clipPath.fill()

    let tabW = 200 * scale
    let tabH = 130 * scale
    let tabRect = NSRect(x: (size - tabW) / 2, y: clipY + clipH - tabH / 2, width: tabW, height: tabH)
    let tabPath = NSBezierPath(roundedRect: tabRect, xRadius: 40 * scale, yRadius: 40 * scale)
    NSColor(calibratedRed: 0.20, green: 0.30, blue: 0.42, alpha: 1.0).setFill()
    tabPath.fill()

    let check = NSBezierPath()
    check.lineWidth = 44 * scale
    check.lineCapStyle = .round
    check.lineJoinStyle = .round
    check.move(to: NSPoint(x: size * 0.315, y: clipY + clipH * 0.44))
    check.line(to: NSPoint(x: size * 0.46, y: clipY + clipH * 0.58))
    check.line(to: NSPoint(x: size * 0.69, y: clipY + clipH * 0.30))
    NSColor(calibratedRed: 0.18, green: 0.80, blue: 0.42, alpha: 1.0).setStroke()
    check.stroke()

    return image
}

let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png")
]

let iconsetDir = outDir.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

for (px, name) in sizes {
    let img = makeIcon(size: CGFloat(px))
    guard let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("Failed to create image for \(name)")
        continue
    }
    let rep = NSBitmapImageRep(cgImage: cg)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: iconsetDir.appendingPathComponent(name))
}

let icnsURL = outDir.appendingPathComponent("AppIcon.icns")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsURL.path]
try? process.run()
process.waitUntilExit()
try? FileManager.default.removeItem(at: iconsetDir)
print("Generated \(icnsURL.path)")
