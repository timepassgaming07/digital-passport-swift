import SwiftUI

struct AmbientBackground: View {
    var isDark: Bool = true
    var body: some View {
        if isDark { DarkBackground() } else { LightBackground() }
    }
}

// MARK: - Dark Background — Deep futuristic blue with cloud/smoke shapes + floating geometry
private struct DarkBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.03)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate

            let s1 = Float(sin(t * 0.08)) * 0.04
            let c1 = Float(cos(t * 0.06)) * 0.03
            let s2 = Float(sin(t * 0.05)) * 0.035
            let c2 = Float(cos(t * 0.09)) * 0.03

            ZStack {
                // Base mesh gradient
                MeshGradient(
                    width: 4, height: 5,
                    points: [
                        SIMD2(0.0, 0.0),   SIMD2(0.33, 0.0),  SIMD2(0.67, 0.0),  SIMD2(1.0, 0.0),
                        SIMD2(0.0, 0.22 + s1),         SIMD2(0.35 + c1, 0.20 + s2),
                        SIMD2(0.65 + s1, 0.24 + c2),   SIMD2(1.0, 0.22 + c1),
                        SIMD2(0.0, 0.45 + c2),         SIMD2(0.38 + s2, 0.43 + c1),
                        SIMD2(0.62 + c1, 0.47 + s1),   SIMD2(1.0, 0.45 + s2),
                        SIMD2(0.0, 0.72 + s2),         SIMD2(0.33 + c2, 0.70 + s1),
                        SIMD2(0.67 + s1, 0.73 + c1),   SIMD2(1.0, 0.72 + c2),
                        SIMD2(0.0, 1.0),   SIMD2(0.33, 1.0),  SIMD2(0.67, 1.0),  SIMD2(1.0, 1.0),
                    ],
                    colors: [
                        Color(red: 0.02, green: 0.03, blue: 0.12),
                        Color(red: 0.03, green: 0.04, blue: 0.16),
                        Color(red: 0.02, green: 0.03, blue: 0.14),
                        Color(red: 0.03, green: 0.05, blue: 0.18),

                        Color(red: 0.04, green: 0.08, blue: 0.22),
                        Color(red: 0.15, green: 0.40, blue: 0.75),
                        Color(red: 0.10, green: 0.55, blue: 0.80),
                        Color(red: 0.03, green: 0.06, blue: 0.20),

                        Color(red: 0.08, green: 0.20, blue: 0.50),
                        Color(red: 0.04, green: 0.06, blue: 0.18),
                        Color(red: 0.12, green: 0.35, blue: 0.65),
                        Color(red: 0.06, green: 0.15, blue: 0.40),

                        Color(red: 0.03, green: 0.05, blue: 0.16),
                        Color(red: 0.06, green: 0.18, blue: 0.45),
                        Color(red: 0.04, green: 0.08, blue: 0.22),
                        Color(red: 0.08, green: 0.25, blue: 0.55),

                        Color(red: 0.02, green: 0.03, blue: 0.10),
                        Color(red: 0.03, green: 0.04, blue: 0.14),
                        Color(red: 0.02, green: 0.03, blue: 0.12),
                        Color(red: 0.03, green: 0.05, blue: 0.15),
                    ]
                )

                // Floating geometric shapes for depth
                FloatingShapes(time: t, isDark: true)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Floating Geometric Shapes
private struct FloatingShapes: View {
    let time: Double
    let isDark: Bool

    init(time: Double, isDark: Bool = true) {
        self.time = time
        self.isDark = isDark
    }

    private var baseHue: (r: CGFloat, g: CGFloat, b: CGFloat) {
        isDark ? (0.12, 0.50, 0.85) : (0.35, 0.55, 0.85)
    }

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let a: CGFloat = isDark ? 1.0 : 0.6 // alpha multiplier for light mode

            // ── Large hexagons ──
            let hex1X = w * 0.78 + CGFloat(sin(time * 0.12)) * 20
            let hex1Y = h * 0.08 + CGFloat(cos(time * 0.09)) * 15
            drawHexagon(in: &context, at: CGPoint(x: hex1X, y: hex1Y),
                        radius: 50, rotation: time * 0.15,
                        color: Color(red: baseHue.r, green: baseHue.g, blue: baseHue.b).opacity(0.08 * a),
                        strokeColor: Color(red: 0.20, green: 0.60, blue: 0.90).opacity(0.14 * a))

            let hex2X = w * 0.22 + CGFloat(cos(time * 0.06)) * 22
            let hex2Y = h * 0.78 + CGFloat(sin(time * 0.08)) * 16
            drawHexagon(in: &context, at: CGPoint(x: hex2X, y: hex2Y),
                        radius: 60, rotation: -time * 0.10,
                        color: Color(red: 0.06, green: 0.30, blue: 0.65).opacity(0.06 * a),
                        strokeColor: Color(red: 0.10, green: 0.45, blue: 0.80).opacity(0.10 * a))

            // NEW: small hexagon cluster — top center
            let hex3X = w * 0.48 + CGFloat(sin(time * 0.11)) * 14
            let hex3Y = h * 0.04 + CGFloat(cos(time * 0.13)) * 8
            drawHexagon(in: &context, at: CGPoint(x: hex3X, y: hex3Y),
                        radius: 25, rotation: time * 0.20,
                        color: Color(red: 0.10, green: 0.42, blue: 0.78).opacity(0.06 * a),
                        strokeColor: Color(red: 0.15, green: 0.55, blue: 0.90).opacity(0.10 * a))

            // NEW: medium hexagon — mid-right area
            let hex4X = w * 0.90 + CGFloat(cos(time * 0.08)) * 16
            let hex4Y = h * 0.45 + CGFloat(sin(time * 0.10)) * 20
            drawHexagon(in: &context, at: CGPoint(x: hex4X, y: hex4Y),
                        radius: 38, rotation: -time * 0.14,
                        color: Color(red: 0.08, green: 0.35, blue: 0.70).opacity(0.05 * a),
                        strokeColor: Color(red: 0.12, green: 0.48, blue: 0.85).opacity(0.09 * a))

            // ── Diamonds ──
            let dia1X = w * 0.12 + CGFloat(sin(time * 0.10)) * 18
            let dia1Y = h * 0.35 + CGFloat(cos(time * 0.14)) * 22
            drawDiamond(in: &context, at: CGPoint(x: dia1X, y: dia1Y),
                        size: 40, rotation: time * 0.18,
                        color: Color(red: 0.10, green: 0.40, blue: 0.75).opacity(0.07 * a),
                        strokeColor: Color(red: 0.12, green: 0.55, blue: 0.85).opacity(0.12 * a))

            let dia2X = w * 0.30 + CGFloat(sin(time * 0.13)) * 12
            let dia2Y = h * 0.15 + CGFloat(cos(time * 0.11)) * 10
            drawDiamond(in: &context, at: CGPoint(x: dia2X, y: dia2Y),
                        size: 22, rotation: time * 0.22,
                        color: Color(red: 0.15, green: 0.55, blue: 0.90).opacity(0.06 * a),
                        strokeColor: Color(red: 0.18, green: 0.60, blue: 0.95).opacity(0.12 * a))

            // NEW: large diamond — center bottom
            let dia3X = w * 0.55 + CGFloat(cos(time * 0.07)) * 24
            let dia3Y = h * 0.90 + CGFloat(sin(time * 0.09)) * 14
            drawDiamond(in: &context, at: CGPoint(x: dia3X, y: dia3Y),
                        size: 48, rotation: -time * 0.12,
                        color: Color(red: 0.08, green: 0.32, blue: 0.68).opacity(0.05 * a),
                        strokeColor: Color(red: 0.12, green: 0.45, blue: 0.82).opacity(0.08 * a))

            // ── Circle Rings ──
            let cir1X = w * 0.72 + CGFloat(cos(time * 0.07)) * 25
            let cir1Y = h * 0.52 + CGFloat(sin(time * 0.11)) * 18
            drawRing(in: &context, at: CGPoint(x: cir1X, y: cir1Y),
                     radius: 32, lineWidth: 1.5,
                     color: Color(red: 0.08, green: 0.45, blue: 0.80).opacity(0.12 * a))

            let cir2X = w * 0.85 + CGFloat(sin(time * 0.09)) * 15
            let cir2Y = h * 0.88 + CGFloat(cos(time * 0.07)) * 12
            drawRing(in: &context, at: CGPoint(x: cir2X, y: cir2Y),
                     radius: 24, lineWidth: 1,
                     color: Color(red: 0.10, green: 0.50, blue: 0.85).opacity(0.10 * a))

            // NEW: double ring — center left
            let cir3X = w * 0.08 + CGFloat(cos(time * 0.06)) * 12
            let cir3Y = h * 0.60 + CGFloat(sin(time * 0.08)) * 18
            drawRing(in: &context, at: CGPoint(x: cir3X, y: cir3Y),
                     radius: 18, lineWidth: 1,
                     color: Color(red: 0.10, green: 0.48, blue: 0.82).opacity(0.08 * a))
            drawRing(in: &context, at: CGPoint(x: cir3X, y: cir3Y),
                     radius: 26, lineWidth: 0.7,
                     color: Color(red: 0.10, green: 0.48, blue: 0.82).opacity(0.05 * a))

            // NEW: pulsing ring — top area
            let pulseR: CGFloat = 20 + CGFloat(sin(time * 0.3)) * 6
            let cir4X = w * 0.62 + CGFloat(sin(time * 0.10)) * 10
            let cir4Y = h * 0.22 + CGFloat(cos(time * 0.08)) * 12
            drawRing(in: &context, at: CGPoint(x: cir4X, y: cir4Y),
                     radius: pulseR, lineWidth: 1.2,
                     color: Color(red: 0.15, green: 0.55, blue: 0.90).opacity(0.10 * a))

            // ── Triangles (NEW) ──
            let tri1X = w * 0.42 + CGFloat(sin(time * 0.09)) * 16
            let tri1Y = h * 0.62 + CGFloat(cos(time * 0.12)) * 14
            drawTriangle(in: &context, at: CGPoint(x: tri1X, y: tri1Y),
                         size: 28, rotation: time * 0.16,
                         color: Color(red: 0.10, green: 0.42, blue: 0.78).opacity(0.05 * a),
                         strokeColor: Color(red: 0.15, green: 0.50, blue: 0.85).opacity(0.09 * a))

            let tri2X = w * 0.88 + CGFloat(cos(time * 0.11)) * 12
            let tri2Y = h * 0.30 + CGFloat(sin(time * 0.07)) * 18
            drawTriangle(in: &context, at: CGPoint(x: tri2X, y: tri2Y),
                         size: 22, rotation: -time * 0.13,
                         color: Color(red: 0.12, green: 0.45, blue: 0.80).opacity(0.04 * a),
                         strokeColor: Color(red: 0.16, green: 0.52, blue: 0.88).opacity(0.08 * a))

            // ── Cross / Plus signs (NEW) ──
            let plus1X = w * 0.18 + CGFloat(sin(time * 0.14)) * 10
            let plus1Y = h * 0.50 + CGFloat(cos(time * 0.10)) * 12
            drawCross(in: &context, at: CGPoint(x: plus1X, y: plus1Y),
                      size: 14, rotation: time * 0.08,
                      color: Color(red: 0.15, green: 0.50, blue: 0.88).opacity(0.10 * a))

            let plus2X = w * 0.65 + CGFloat(cos(time * 0.09)) * 8
            let plus2Y = h * 0.72 + CGFloat(sin(time * 0.12)) * 10
            drawCross(in: &context, at: CGPoint(x: plus2X, y: plus2Y),
                      size: 10, rotation: -time * 0.10,
                      color: Color(red: 0.12, green: 0.48, blue: 0.85).opacity(0.08 * a))

            // ── Particle dots (expanded) ──
            for i in 0..<14 {
                let d = Double(i)
                let dx = w * CGFloat(fmod(0.06 + d * 0.07, 1.0)) + CGFloat(sin(time * 0.15 + d)) * 8
                let dy = h * CGFloat(fmod(0.08 + d * 0.075, 1.0)) + CGFloat(cos(time * 0.12 + d * 0.5)) * 6
                let dotR: CGFloat = CGFloat(1.5 + sin(time * 0.2 + d) * 0.8)
                context.fill(
                    Path(ellipseIn: CGRect(x: dx - dotR, y: dy - dotR, width: dotR * 2, height: dotR * 2)),
                    with: .color(Color(red: 0.20, green: 0.60, blue: 0.95).opacity(0.14 * a))
                )
            }

            // ── Connecting lines between nearby shapes (NEW) ──
            drawLine(in: &context,
                     from: CGPoint(x: hex1X, y: hex1Y), to: CGPoint(x: cir4X, y: cir4Y),
                     color: Color(red: 0.12, green: 0.48, blue: 0.82).opacity(0.04 * a))
            drawLine(in: &context,
                     from: CGPoint(x: dia1X, y: dia1Y), to: CGPoint(x: cir3X, y: cir3Y),
                     color: Color(red: 0.12, green: 0.48, blue: 0.82).opacity(0.03 * a))
        }
    }

    private func drawHexagon(in context: inout GraphicsContext, at center: CGPoint,
                             radius: CGFloat, rotation: Double,
                             color: Color, strokeColor: Color) {
        var path = Path()
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3.0 + rotation
            let pt = CGPoint(x: center.x + radius * CGFloat(cos(angle)),
                             y: center.y + radius * CGFloat(sin(angle)))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        context.fill(path, with: .color(color))
        context.stroke(path, with: .color(strokeColor), lineWidth: 1)
    }

    private func drawDiamond(in context: inout GraphicsContext, at center: CGPoint,
                             size: CGFloat, rotation: Double,
                             color: Color, strokeColor: Color) {
        let s = size / 2
        var path = Path()
        let pts: [(CGFloat, CGFloat)] = [(0, -s), (s, 0), (0, s), (-s, 0)]
        for (i, pt) in pts.enumerated() {
            let rx = pt.0 * CGFloat(cos(rotation)) - pt.1 * CGFloat(sin(rotation))
            let ry = pt.0 * CGFloat(sin(rotation)) + pt.1 * CGFloat(cos(rotation))
            let p = CGPoint(x: center.x + rx, y: center.y + ry)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        context.fill(path, with: .color(color))
        context.stroke(path, with: .color(strokeColor), lineWidth: 1)
    }

    private func drawTriangle(in context: inout GraphicsContext, at center: CGPoint,
                              size: CGFloat, rotation: Double,
                              color: Color, strokeColor: Color) {
        var path = Path()
        for i in 0..<3 {
            let angle = Double(i) * 2.0 * .pi / 3.0 + rotation - .pi / 2.0
            let pt = CGPoint(x: center.x + size * CGFloat(cos(angle)),
                             y: center.y + size * CGFloat(sin(angle)))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        context.fill(path, with: .color(color))
        context.stroke(path, with: .color(strokeColor), lineWidth: 0.8)
    }

    private func drawCross(in context: inout GraphicsContext, at center: CGPoint,
                           size: CGFloat, rotation: Double, color: Color) {
        let s = size / 2
        let pts: [(CGFloat, CGFloat)] = [(-s, 0), (s, 0), (0, -s), (0, s)]
        for i in stride(from: 0, to: pts.count, by: 2) {
            var line = Path()
            let a = pts[i], b = pts[i + 1]
            let ax = a.0 * CGFloat(cos(rotation)) - a.1 * CGFloat(sin(rotation))
            let ay = a.0 * CGFloat(sin(rotation)) + a.1 * CGFloat(cos(rotation))
            let bx = b.0 * CGFloat(cos(rotation)) - b.1 * CGFloat(sin(rotation))
            let by = b.0 * CGFloat(sin(rotation)) + b.1 * CGFloat(cos(rotation))
            line.move(to: CGPoint(x: center.x + ax, y: center.y + ay))
            line.addLine(to: CGPoint(x: center.x + bx, y: center.y + by))
            context.stroke(line, with: .color(color), lineWidth: 1.2)
        }
    }

    private func drawRing(in context: inout GraphicsContext, at center: CGPoint,
                          radius: CGFloat, lineWidth: CGFloat, color: Color) {
        let path = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                          width: radius * 2, height: radius * 2))
        context.stroke(path, with: .color(color), lineWidth: lineWidth)
    }

    private func drawLine(in context: inout GraphicsContext,
                          from: CGPoint, to: CGPoint, color: Color) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 0.5, dash: [4, 6]))
    }
}

// MARK: - Light Background — Luxury pearl with soft blue glass warmth
private struct LightBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.03)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate

            let s1 = Float(sin(t * 0.06)) * 0.03
            let c1 = Float(cos(t * 0.05)) * 0.025
            let s2 = Float(sin(t * 0.04)) * 0.03
            let c2 = Float(cos(t * 0.07)) * 0.025

            ZStack {
                MeshGradient(
                    width: 4, height: 5,
                    points: [
                        SIMD2(0.0, 0.0),   SIMD2(0.33, 0.0),  SIMD2(0.67, 0.0),  SIMD2(1.0, 0.0),
                        SIMD2(0.0, 0.22 + s1),   SIMD2(0.35 + c1, 0.20 + s2),
                        SIMD2(0.65 + s1, 0.24 + c2),  SIMD2(1.0, 0.22 + c1),
                        SIMD2(0.0, 0.45 + c2),   SIMD2(0.38 + s2, 0.43 + c1),
                        SIMD2(0.62 + c1, 0.47 + s1),  SIMD2(1.0, 0.45 + s2),
                        SIMD2(0.0, 0.72 + s2),   SIMD2(0.33 + c2, 0.70 + s1),
                        SIMD2(0.67 + s1, 0.73 + c1),  SIMD2(1.0, 0.72 + c2),
                        SIMD2(0.0, 1.0),   SIMD2(0.33, 1.0),  SIMD2(0.67, 1.0),  SIMD2(1.0, 1.0),
                    ],
                    colors: [
                        // Row 0 — warm pearl white top
                        Color(red: 0.96, green: 0.97, blue: 0.99),
                        Color(red: 0.93, green: 0.95, blue: 0.99),
                        Color(red: 0.95, green: 0.96, blue: 0.99),
                        Color(red: 0.92, green: 0.95, blue: 0.99),

                        // Row 1 — soft blue glass cloud
                        Color(red: 0.88, green: 0.93, blue: 0.99),
                        Color(red: 0.72, green: 0.85, blue: 0.98),  // blue cloud
                        Color(red: 0.68, green: 0.88, blue: 0.99),  // cyan cloud
                        Color(red: 0.90, green: 0.94, blue: 0.99),

                        // Row 2 — pearl with lavender hints
                        Color(red: 0.85, green: 0.88, blue: 0.97),  // lavender
                        Color(red: 0.94, green: 0.96, blue: 0.99),  // bright white
                        Color(red: 0.78, green: 0.87, blue: 0.98),  // blue mist
                        Color(red: 0.88, green: 0.92, blue: 0.99),

                        // Row 3 — soft warm blue
                        Color(red: 0.92, green: 0.94, blue: 0.98),
                        Color(red: 0.82, green: 0.90, blue: 0.99),  // subtle blue
                        Color(red: 0.90, green: 0.93, blue: 0.98),
                        Color(red: 0.76, green: 0.86, blue: 0.97),  // soft blue

                        // Row 4 — clean white bottom
                        Color(red: 0.95, green: 0.96, blue: 0.99),
                        Color(red: 0.93, green: 0.95, blue: 0.98),
                        Color(red: 0.94, green: 0.96, blue: 0.99),
                        Color(red: 0.92, green: 0.95, blue: 0.98),
                    ]
                )

                // Floating shapes in light mode too (subtle)
                FloatingShapes(time: t, isDark: false)
            }
            .ignoresSafeArea()
        }
    }
}

extension View {
    func ambientBackground() -> some View {
        ZStack { AmbientBackground(); self }
    }
}
