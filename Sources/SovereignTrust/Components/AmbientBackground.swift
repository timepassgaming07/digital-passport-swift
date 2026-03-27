import SwiftUI

struct AmbientBackground: View {
    var isDark: Bool = true
    var body: some View {
        if isDark { DarkBackground() } else { LightBackground() }
    }
}

// MARK: - Dark Background — Deep futuristic blue with cloud/smoke shapes
private struct DarkBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.03)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate

            let s1 = Float(sin(t * 0.08)) * 0.04
            let c1 = Float(cos(t * 0.06)) * 0.03
            let s2 = Float(sin(t * 0.05)) * 0.035
            let c2 = Float(cos(t * 0.09)) * 0.03

            // Base: animated MeshGradient — deep navy with bright blue/cyan cloud patches
            MeshGradient(
                width: 4, height: 5,
                points: [
                    // Row 0 — top
                    SIMD2(0.0, 0.0),   SIMD2(0.33, 0.0),  SIMD2(0.67, 0.0),  SIMD2(1.0, 0.0),
                    // Row 1
                    SIMD2(0.0, 0.22 + s1),         SIMD2(0.35 + c1, 0.20 + s2),
                    SIMD2(0.65 + s1, 0.24 + c2),   SIMD2(1.0, 0.22 + c1),
                    // Row 2
                    SIMD2(0.0, 0.45 + c2),         SIMD2(0.38 + s2, 0.43 + c1),
                    SIMD2(0.62 + c1, 0.47 + s1),   SIMD2(1.0, 0.45 + s2),
                    // Row 3
                    SIMD2(0.0, 0.72 + s2),         SIMD2(0.33 + c2, 0.70 + s1),
                    SIMD2(0.67 + s1, 0.73 + c1),   SIMD2(1.0, 0.72 + c2),
                    // Row 4 — bottom
                    SIMD2(0.0, 1.0),   SIMD2(0.33, 1.0),  SIMD2(0.67, 1.0),  SIMD2(1.0, 1.0),
                ],
                colors: [
                    // Row 0 — very deep navy/near black
                    Color(red: 0.02, green: 0.03, blue: 0.12),
                    Color(red: 0.03, green: 0.04, blue: 0.16),
                    Color(red: 0.02, green: 0.03, blue: 0.14),
                    Color(red: 0.03, green: 0.05, blue: 0.18),

                    // Row 1 — dramatic bright blue cloud burst
                    Color(red: 0.04, green: 0.08, blue: 0.22),
                    Color(red: 0.15, green: 0.40, blue: 0.75),  // bright blue cloud
                    Color(red: 0.10, green: 0.55, blue: 0.80),  // cyan cloud
                    Color(red: 0.03, green: 0.06, blue: 0.20),

                    // Row 2 — mixed blue smoke + dark gaps
                    Color(red: 0.08, green: 0.20, blue: 0.50),  // mid-blue
                    Color(red: 0.04, green: 0.06, blue: 0.18),  // dark gap
                    Color(red: 0.12, green: 0.35, blue: 0.65),  // blue smoke
                    Color(red: 0.06, green: 0.15, blue: 0.40),

                    // Row 3 — deep with subtle cyan hints
                    Color(red: 0.03, green: 0.05, blue: 0.16),
                    Color(red: 0.06, green: 0.18, blue: 0.45),  // subtle blue patch
                    Color(red: 0.04, green: 0.08, blue: 0.22),
                    Color(red: 0.08, green: 0.25, blue: 0.55),  // subtle cyan

                    // Row 4 — deep navy bottom
                    Color(red: 0.02, green: 0.03, blue: 0.10),
                    Color(red: 0.03, green: 0.04, blue: 0.14),
                    Color(red: 0.02, green: 0.03, blue: 0.12),
                    Color(red: 0.03, green: 0.05, blue: 0.15),
                ]
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Light Background
private struct LightBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.03)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate

            let s1 = Float(sin(t * 0.08)) * 0.04
            let c1 = Float(cos(t * 0.06)) * 0.03
            let s2 = Float(sin(t * 0.05)) * 0.035
            let c2 = Float(cos(t * 0.09)) * 0.03

            MeshGradient(
                width: 3, height: 4,
                points: [
                    SIMD2(0.0, 0.0),  SIMD2(0.5, 0.0),   SIMD2(1.0, 0.0),
                    SIMD2(0.0, 0.30 + s1),  SIMD2(0.5 + c2, 0.33 + s1), SIMD2(1.0, 0.30 + c2),
                    SIMD2(0.0, 0.65 + s2),  SIMD2(0.5 + s1, 0.68 + c2), SIMD2(1.0, 0.65 + s1),
                    SIMD2(0.0, 1.0),  SIMD2(0.5, 1.0),   SIMD2(1.0, 1.0),
                ],
                colors: [
                    Color(red: 0.88, green: 0.93, blue: 0.99),
                    Color(red: 0.82, green: 0.90, blue: 0.98),
                    Color(red: 0.90, green: 0.92, blue: 0.98),

                    Color(red: 0.78, green: 0.88, blue: 0.98),
                    Color(red: 0.90, green: 0.95, blue: 1.00),
                    Color(red: 0.75, green: 0.86, blue: 0.97),

                    Color(red: 0.85, green: 0.92, blue: 1.00),
                    Color(red: 0.80, green: 0.90, blue: 0.98),
                    Color(red: 0.88, green: 0.94, blue: 1.00),

                    Color(red: 0.85, green: 0.91, blue: 0.98),
                    Color(red: 0.82, green: 0.90, blue: 0.97),
                    Color(red: 0.86, green: 0.92, blue: 0.99),
                ]
            )
            .ignoresSafeArea()
        }
    }
}

extension View {
    func ambientBackground() -> some View {
        ZStack { AmbientBackground(); self }
    }
}
