import Cocoa

// POV toilet overlay: a transparent, always-on-top, click-through window.
// Put your iPhone Mirroring window BEHIND it, sized into the clear phone hole.
// Run:  swift overlay.swift                  (built-in cartoon frame)
//       swift overlay.swift hands.png        (your own PNG; phone area transparent)
// Quit: Cmd-Q  (or Ctrl-C in the terminal)

let imagePath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : nil

final class FrameView: NSView {
    var image: NSImage?
    var hole = NSRect.zero  // transparent phone-screen rect (printed on launch)

    override func draw(_ dirty: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)

        if let image = image {
            image.draw(in: bounds)  // user PNG: alpha defines the screen hole
            return
        }

        // --- built-in cartoon POV: two thighs + a phone with a clear screen ---
        let skin = NSColor(calibratedRed: 0.86, green: 0.67, blue: 0.53, alpha: 1)
        skin.setFill()
        let w = bounds.width, h = bounds.height
        // left & right thigh wedges rising from bottom corners
        for sign in [CGFloat(-1), 1] {
            let p = NSBezierPath()
            let cx = sign < 0 ? CGFloat(0) : w
            p.move(to: NSPoint(x: cx, y: 0))
            p.line(to: NSPoint(x: cx, y: h * 0.55))
            p.curve(to: NSPoint(x: w/2 + sign * w * 0.05, y: 0),
                    controlPoint1: NSPoint(x: cx - sign * w * 0.18, y: h * 0.35),
                    controlPoint2: NSPoint(x: w/2 + sign * w * 0.18, y: h * 0.18))
            p.close()
            p.fill()
        }

        // phone body, centered, lower third
        let pw = min(w * 0.34, 460), ph = pw * 2.05
        let phone = NSRect(x: (w - pw)/2, y: h * 0.06, width: pw, height: ph)
        NSColor(white: 0.08, alpha: 1).setFill()
        NSBezierPath(roundedRect: phone, xRadius: pw*0.12, yRadius: pw*0.12).fill()

        // clear screen hole -> iPhone Mirroring shows through here
        hole = phone.insetBy(dx: pw*0.05, dy: pw*0.05)
        ctx.clear(hole)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let screen = NSScreen.main!.frame
let window = NSWindow(contentRect: screen, styleMask: .borderless,
                     backing: .buffered, defer: false)
window.isOpaque = false
window.backgroundColor = .clear
window.level = .floating                 // above normal windows incl. iPhone Mirroring
window.ignoresMouseEvents = true         // click-through to the phone behind
window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
window.hasShadow = false

let view = FrameView(frame: screen)
if let p = imagePath { view.image = NSImage(contentsOfFile: p) }
window.contentView = view
window.makeKeyAndOrderFront(nil)
window.orderFrontRegardless()

if imagePath == nil {
    view.layoutSubtreeIfNeeded(); view.display()
    let r = view.hole
    print("Phone screen hole (screen coords): x=\(Int(r.minX)) y=\(Int(r.minY)) w=\(Int(r.width)) h=\(Int(r.height))")
    print("→ Drag/resize iPhone Mirroring to fit that rectangle, behind this overlay.")
}

app.run()
