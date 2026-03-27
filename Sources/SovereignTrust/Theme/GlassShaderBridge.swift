import SwiftUI

// MARK: - Metal Glass Distortion Modifier
/// Applies a subtle edge-refraction distortion using Metal .layerEffect.
/// This is an ENHANCEMENT ONLY — the native Material does the actual blur.
/// Requires iOS 17+ for ShaderLibrary / .layerEffect.
struct GlassDistortionModifier: ViewModifier {
    /// 0…1 range. Keep below 0.5 for subtlety.
    var intensity: Float = 0.3
    @State private var time: Float = 0

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let now = Float(timeline.date.timeIntervalSinceReferenceDate)
            content
                .visualEffect { view, proxy in
                    view.layerEffect(
                        ShaderLibrary.glassDistortion(
                            .float2(Float(proxy.size.width), Float(proxy.size.height)),
                            .float(now),
                            .float(intensity)
                        ),
                        maxSampleOffset: CGSize(width: 3, height: 3),
                        isEnabled: intensity > 0
                    )
                }
        }
    }
}

// MARK: - Chromatic Edge Modifier
/// Very subtle chromatic separation at glass edges.
struct GlassChromaticModifier: ViewModifier {
    var intensity: Float = 0.3

    func body(content: Content) -> some View {
        content
            .visualEffect { view, proxy in
                view.layerEffect(
                    ShaderLibrary.glassChromaticEdge(
                        .float2(Float(proxy.size.width), Float(proxy.size.height)),
                        .float(intensity)
                    ),
                    maxSampleOffset: CGSize(width: 2, height: 2),
                    isEnabled: intensity > 0
                )
            }
    }
}

// MARK: - Convenience Extensions
extension View {
    /// Apply subtle glass edge distortion (Metal shader).
    func glassDistortion(intensity: Float = 0.3) -> some View {
        modifier(GlassDistortionModifier(intensity: intensity))
    }

    /// Apply subtle chromatic edge effect (Metal shader).
    func glassChromaticEdge(intensity: Float = 0.25) -> some View {
        modifier(GlassChromaticModifier(intensity: intensity))
    }
}
