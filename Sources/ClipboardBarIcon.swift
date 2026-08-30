import AppKit

enum ClipboardBarIcon {
    // Draws a clipboard-with-checkmark as a monochrome template image
    // so it matches the app icon theme and adapts to light/dark menu bars.
    static func makeMenuBarIcon(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.isTemplate = true
        image.lockFocus()
        defer { image.unlockFocus() }

        let scale: CGFloat = size / 18.0

        let color = NSColor.black
        color.setFill()
        color.setStroke()

        let clipW = 12 * scale
        let clipH = 14 * scale
        let clipX = (size - clipW) / 2
        let clipY = (size - clipH) / 2

        // Clipboard body
        let body = NSBezierPath(roundedRect: NSRect(x: clipX, y: clipY, width: clipW, height: clipH), xRadius: 2 * scale, yRadius: 2 * scale)
        body.lineWidth = 1.6 * scale
        body.stroke()

        // Top tab
        let tabPath = NSBezierPath()
        tabPath.lineWidth = 1.6 * scale
        tabPath.move(to: NSPoint(x: clipX + 2 * scale, y: clipY + clipH))
        tabPath.line(to: NSPoint(x: clipX + 2 * scale, y: clipY + clipH + 2.2 * scale))
        tabPath.appendArc(withCenter: NSPoint(x: clipX + clipW / 2, y: clipY + clipH + 2.2 * scale), radius: 4 * scale, startAngle: 180, endAngle: 0)
        tabPath.move(to: NSPoint(x: clipX + clipW - 2 * scale, y: clipY + clipH + 2.2 * scale))
        tabPath.close()
        tabPath.line(to: NSPoint(x: clipX + clipW - 2 * scale, y: clipY + clipH))
        tabPath.stroke()

        // Checkmark
        let check = NSBezierPath()
        check.lineWidth = 2 * scale
        check.lineCapStyle = .round
        check.lineJoinStyle = .round
        check.move(to: NSPoint(x: clipX + 3 * scale, y: clipY + clipH * 0.46))
        check.line(to: NSPoint(x: clipX + clipW * 0.42, y: clipY + clipH * 0.6))
        check.line(to: NSPoint(x: clipX + clipW - 3 * scale, y: clipY + clipH * 0.34))
        check.stroke()

        return image
    }
}
