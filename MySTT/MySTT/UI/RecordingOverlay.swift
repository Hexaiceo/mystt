import AppKit
import QuartzCore

/// Animated overlay with pulsing concentric rings (matching app icon style)
@MainActor
class RecordingOverlayWindow {
    private var window: NSWindow?
    private var animationView: ListeningAnimationView?
    private var label: NSTextField?
    private var currentStatus: Status?

    // Small status indicator for loading/not-ready states
    private var statusWindow: NSWindow?
    private var statusIcon: NSView?
    private var statusLabel: NSTextField?
    private var statusPulseTimer: Timer?

    func show(status: Status, detail: String = "") {
        // Hide the small status indicator when showing the main overlay
        hideStatusIndicator()

        let text: String
        switch status {
        case .listening:
            text = detail.isEmpty ? "Listening..." : "Listening... \(detail)"
        case .processing:
            text = detail.isEmpty ? "Processing..." : detail
        case .done:
            text = detail.isEmpty ? "Done!" : "Done! \(detail)"
        }

        currentStatus = status

        if let win = window, let lbl = label, let anim = animationView {
            lbl.stringValue = text
            anim.setStatus(status)
            win.orderFront(nil)
            return
        }

        // Create window — compact size
        let animSize: CGFloat = 36
        let padding: CGFloat = 6
        let labelH: CGFloat = 14
        let winW: CGFloat = animSize + padding * 2
        let winH: CGFloat = animSize + labelH + padding * 3
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: winW, height: winH),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.hasShadow = false
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let container = NSView(frame: NSRect(x: 0, y: 0, width: winW, height: winH))
        container.wantsLayer = true

        // Background pill
        let bg = NSView(frame: NSRect(x: 0, y: 0, width: winW, height: winH))
        bg.wantsLayer = true
        bg.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        bg.layer?.cornerRadius = 10
        container.addSubview(bg)

        // Animation view
        let anim = ListeningAnimationView(frame: NSRect(x: padding, y: labelH + padding * 2, width: animSize, height: animSize))
        anim.setStatus(status)
        container.addSubview(anim)
        self.animationView = anim

        // Label
        let lbl = NSTextField(labelWithString: text)
        lbl.font = NSFont.systemFont(ofSize: 8, weight: .medium)
        lbl.textColor = .white
        lbl.alignment = .center
        lbl.frame = NSRect(x: 2, y: padding - 1, width: winW - 4, height: labelH)
        lbl.isEditable = false
        lbl.isBordered = false
        lbl.backgroundColor = .clear
        container.addSubview(lbl)
        self.label = lbl

        win.contentView = container

        if let screen = NSScreen.main {
            win.setFrameOrigin(NSPoint(
                x: screen.visibleFrame.midX - winW / 2,
                y: screen.visibleFrame.minY + 40
            ))
        }

        win.orderFront(nil)
        self.window = win
    }

    func hide() {
        animationView?.stopAnimating()
        window?.orderOut(nil)
        currentStatus = nil
    }

    // MARK: - Small Status Indicator (loading/not-ready)

    func showStatusIndicator(mode: StatusIndicatorMode) {
        // Don't show if main overlay is visible
        if window?.isVisible == true { return }

        let text: String
        let color: NSColor
        let iconName: String
        let shouldPulse: Bool

        switch mode {
        case .loading(let detail):
            text = detail.isEmpty ? "Loading..." : detail
            color = .systemOrange
            iconName = "arrow.down.circle.fill"
            shouldPulse = true
        case .notReady(let detail):
            text = detail.isEmpty ? "Not ready" : detail
            color = .systemRed
            iconName = "exclamationmark.circle.fill"
            shouldPulse = false
        }

        if let win = statusWindow, let lbl = statusLabel, let icon = statusIcon {
            lbl.stringValue = text
            // Update icon color
            if let imageView = icon as? NSImageView {
                imageView.contentTintColor = color
                if let img = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
                    imageView.image = img
                }
            }
            win.orderFront(nil)
            if shouldPulse { startStatusPulse(icon: icon, color: color) } else { stopStatusPulse() }
            return
        }

        // Create small indicator window
        let winW: CGFloat = 120
        let winH: CGFloat = 28
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: winW, height: winH),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.hasShadow = false
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let container = NSView(frame: NSRect(x: 0, y: 0, width: winW, height: winH))
        container.wantsLayer = true

        // Background pill
        let bg = NSView(frame: NSRect(x: 0, y: 0, width: winW, height: winH))
        bg.wantsLayer = true
        bg.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.75).cgColor
        bg.layer?.cornerRadius = winH / 2
        container.addSubview(bg)

        // Icon
        let iconSize: CGFloat = 16
        let iconView = NSImageView(frame: NSRect(x: 8, y: (winH - iconSize) / 2, width: iconSize, height: iconSize))
        if let img = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            iconView.image = img
        }
        iconView.contentTintColor = color
        iconView.wantsLayer = true
        container.addSubview(iconView)
        self.statusIcon = iconView

        // Label
        let lbl = NSTextField(labelWithString: text)
        lbl.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        lbl.textColor = .white
        lbl.alignment = .left
        lbl.frame = NSRect(x: 28, y: (winH - 14) / 2, width: winW - 36, height: 14)
        lbl.isEditable = false
        lbl.isBordered = false
        lbl.backgroundColor = .clear
        lbl.lineBreakMode = .byTruncatingTail
        container.addSubview(lbl)
        self.statusLabel = lbl

        win.contentView = container

        if let screen = NSScreen.main {
            win.setFrameOrigin(NSPoint(
                x: screen.visibleFrame.midX - winW / 2,
                y: screen.visibleFrame.minY + 40
            ))
        }

        win.orderFront(nil)
        self.statusWindow = win

        if shouldPulse { startStatusPulse(icon: iconView, color: color) }
    }

    func hideStatusIndicator() {
        stopStatusPulse()
        statusWindow?.orderOut(nil)
    }

    private func startStatusPulse(icon: NSView, color: NSColor) {
        stopStatusPulse()
        icon.wantsLayer = true

        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1.0
        pulse.toValue = 0.3
        pulse.duration = 1.0
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        icon.layer?.add(pulse, forKey: "statusPulse")
    }

    private func stopStatusPulse() {
        statusIcon?.layer?.removeAnimation(forKey: "statusPulse")
        statusIcon?.layer?.opacity = 1.0
    }

    enum Status {
        case listening, processing, done
    }

    enum StatusIndicatorMode {
        case loading(detail: String)
        case notReady(detail: String)
    }
}

// MARK: - Listening Animation View (pulsing concentric rings)

class ListeningAnimationView: NSView {
    private var ringLayers: [CAShapeLayer] = []
    private var centerDot: CAShapeLayer?
    private var displayLink: CVDisplayLink?
    private var pulseTimer: Timer?
    private var isAnimating = false

    // App icon colors: deep purple → lighter purple with glow
    private let colors: [NSColor] = [
        NSColor(red: 0.40, green: 0.20, blue: 0.90, alpha: 1.0),   // bright purple
        NSColor(red: 0.50, green: 0.25, blue: 0.95, alpha: 0.8),   // mid purple
        NSColor(red: 0.60, green: 0.35, blue: 1.00, alpha: 0.6),   // light purple
        NSColor(red: 0.45, green: 0.30, blue: 0.85, alpha: 0.4),   // faded purple
    ]

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        setupRings()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupRings() {
        guard let layer = self.layer else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let maxRadius = min(bounds.width, bounds.height) / 2 - 4

        // Create 4 concentric rings
        for i in 0..<4 {
            let radius = maxRadius * CGFloat(4 - i) / 4.0
            let ring = CAShapeLayer()
            ring.path = CGPath(ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            ), transform: nil)
            ring.fillColor = NSColor.clear.cgColor
            ring.strokeColor = colors[i].cgColor
            ring.lineWidth = 1.0
            ring.opacity = 0
            layer.addSublayer(ring)
            ringLayers.append(ring)
        }

        // Center dot
        let dotRadius: CGFloat = 3
        let dot = CAShapeLayer()
        dot.path = CGPath(ellipseIn: CGRect(
            x: center.x - dotRadius, y: center.y - dotRadius,
            width: dotRadius * 2, height: dotRadius * 2
        ), transform: nil)
        dot.fillColor = colors[0].cgColor
        dot.opacity = 0
        layer.addSublayer(dot)
        self.centerDot = dot
    }

    func setStatus(_ status: RecordingOverlayWindow.Status) {
        stopAnimating()

        switch status {
        case .listening:
            startListeningAnimation()
        case .processing:
            startProcessingAnimation()
        case .done:
            showDoneAnimation()
        }
    }

    private func startListeningAnimation() {
        isAnimating = true

        // Fade in center dot
        let dotFade = CABasicAnimation(keyPath: "opacity")
        dotFade.fromValue = 0
        dotFade.toValue = 1
        dotFade.duration = 0.3
        dotFade.fillMode = .forwards
        dotFade.isRemovedOnCompletion = false
        centerDot?.add(dotFade, forKey: "fadeIn")

        // Pulsing dot
        let dotPulse = CABasicAnimation(keyPath: "transform.scale")
        dotPulse.fromValue = 0.8
        dotPulse.toValue = 1.2
        dotPulse.duration = 0.6
        dotPulse.autoreverses = true
        dotPulse.repeatCount = .infinity
        dotPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        centerDot?.add(dotPulse, forKey: "pulse")

        // Staggered ring pulse outward
        for (i, ring) in ringLayers.enumerated() {
            let delay = Double(i) * 0.25

            // Fade in/out
            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0.0, 0.8, 0.0]
            fade.keyTimes = [0.0, 0.3, 1.0]
            fade.duration = 1.8
            fade.beginTime = CACurrentMediaTime() + delay
            fade.repeatCount = .infinity
            fade.timingFunction = CAMediaTimingFunction(name: .easeOut)
            ring.add(fade, forKey: "fade")

            // Scale pulse
            let scale = CAKeyframeAnimation(keyPath: "transform.scale")
            scale.values = [0.6, 1.0, 1.15]
            scale.keyTimes = [0.0, 0.4, 1.0]
            scale.duration = 1.8
            scale.beginTime = CACurrentMediaTime() + delay
            scale.repeatCount = .infinity
            scale.timingFunction = CAMediaTimingFunction(name: .easeOut)
            ring.add(scale, forKey: "scale")

            // Glow (shadow)
            let glow = CABasicAnimation(keyPath: "shadowOpacity")
            glow.fromValue = 0.0
            glow.toValue = 0.8
            glow.duration = 0.9
            glow.autoreverses = true
            glow.beginTime = CACurrentMediaTime() + delay
            glow.repeatCount = .infinity
            ring.shadowColor = colors[i].cgColor
            ring.shadowRadius = 3
            ring.shadowOffset = .zero
            ring.add(glow, forKey: "glow")
        }
    }

    private func startProcessingAnimation() {
        isAnimating = true

        // Spinning ring effect
        centerDot?.opacity = 1

        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = Double.pi * 2
        spin.duration = 2.0
        spin.repeatCount = .infinity
        centerDot?.add(spin, forKey: "spin")

        for (i, ring) in ringLayers.enumerated() {
            ring.opacity = Float(0.3 + Double(i) * 0.1)
            ring.strokeColor = NSColor.systemOrange.withAlphaComponent(0.5 + Double(i) * 0.1).cgColor

            let breathe = CABasicAnimation(keyPath: "opacity")
            breathe.fromValue = 0.2
            breathe.toValue = 0.6
            breathe.duration = 1.0 + Double(i) * 0.2
            breathe.autoreverses = true
            breathe.repeatCount = .infinity
            ring.add(breathe, forKey: "breathe")
        }
    }

    private func showDoneAnimation() {
        centerDot?.opacity = 1
        centerDot?.fillColor = NSColor.systemGreen.cgColor

        let pop = CAKeyframeAnimation(keyPath: "transform.scale")
        pop.values = [0.5, 1.3, 1.0]
        pop.keyTimes = [0, 0.5, 1.0]
        pop.duration = 0.4
        centerDot?.add(pop, forKey: "pop")

        for (i, ring) in ringLayers.enumerated() {
            ring.strokeColor = NSColor.systemGreen.withAlphaComponent(0.6).cgColor
            ring.opacity = Float(0.6 - Double(i) * 0.15)
        }
    }

    func stopAnimating() {
        isAnimating = false
        centerDot?.removeAllAnimations()
        centerDot?.opacity = 0
        centerDot?.fillColor = colors[0].cgColor

        for (i, ring) in ringLayers.enumerated() {
            ring.removeAllAnimations()
            ring.opacity = 0
            ring.strokeColor = colors[i].cgColor
        }
    }
}
