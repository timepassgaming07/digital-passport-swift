import SwiftUI

enum GlassStyle {
    case liquid, frost, thick
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 22
    var glowColor: Color = .clear
    var glowOpacity: Double = 0
    var innerPadding: CGFloat = 16
    var style: GlassStyle = .liquid
    var material: AnyShapeStyle? = nil
    @ViewBuilder let content: () -> Content

    // Same material system as iOS tab bar
    private var cardMaterial: AnyShapeStyle {
        if let m = material { return m }
        switch style {
        case .liquid: return AnyShapeStyle(.ultraThinMaterial)  // Tab bar level — most transparent
        case .frost:  return AnyShapeStyle(.thinMaterial)       // Slightly more opaque
        case .thick:  return AnyShapeStyle(.regularMaterial)    // Hero cards
        }
    }

    var body: some View {
        content()
            .padding(innerPadding)
            // EXACT same as tab bar: .ultraThinMaterial shape
            .background(cardMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            // Single bright edge stroke — matches tab bar border exactly
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.25),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            // Trust glow only (no extra shadows that muddy the glass)
            .shadow(color: glowColor.opacity(glowOpacity), radius: 20, x: 0, y: 0)
            .shadow(color: .black.opacity(0.22), radius: 16, x: 0, y: 6)
    }
}

struct GlassPressModifier: ViewModifier {
    @State private var pressed = false
    let action: () -> Void
    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.97 : 1.0)
            .brightness(pressed ? 0.03 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: pressed)
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false })
            .onTapGesture(perform: action)
    }
}
extension View {
    func glassPress(action: @escaping () -> Void) -> some View {
        modifier(GlassPressModifier(action: action))
    }
}
