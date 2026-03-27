import SwiftUI

// MARK: - Liquid Glass Configuration
struct LiquidGlassConfig {
    var cornerRadius: CGFloat = 22
    var glowColor: Color = .clear
    var glowIntensity: Double = 0
    var glassType: Glass = .clear

    static let card = LiquidGlassConfig()
    static let heroCard = LiquidGlassConfig(cornerRadius: 28)
    static let navBar = LiquidGlassConfig(cornerRadius: 0)
    static let floatingPanel = LiquidGlassConfig(cornerRadius: 28)
    static let button = LiquidGlassConfig(cornerRadius: .infinity)
    static let input = LiquidGlassConfig(cornerRadius: 14)
    static let tabBar = LiquidGlassConfig(cornerRadius: 0)
}

// MARK: - Core Liquid Glass Modifier (iOS 26 Native)
struct LiquidGlassModifier: ViewModifier {
    let config: LiquidGlassConfig

    func body(content: Content) -> some View {
        content
            .glassEffect(
                config.glowColor != .clear
                    ? config.glassType.tint(config.glowColor.opacity(config.glowIntensity))
                    : config.glassType,
                in: .rect(cornerRadius: config.cornerRadius)
            )
    }
}

// MARK: - Glass Press
struct LiquidGlassPressModifier: ViewModifier {
    let action: () -> Void
    @State private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.97 : 1.0)
            .brightness(pressed ? 0.03 : 0)
            .animation(.spring(response: 0.26, dampingFraction: 0.74), value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded   { _ in pressed = false }
            )
            .onTapGesture(perform: action)
    }
}

// MARK: — Convenience Extensions
extension View {

    func liquidGlass(_ config: LiquidGlassConfig = .card) -> some View {
        modifier(LiquidGlassModifier(config: config))
    }

    func glass(
        cornerRadius: CGFloat = 22,
        glow: Color = .clear,
        glowIntensity: Double = 0
    ) -> some View {
        self.glassEffect(
            glow != .clear
                ? Glass.clear.tint(glow.opacity(glowIntensity))
                : .clear,
            in: .rect(cornerRadius: cornerRadius)
        )
    }

    func glassCard(
        cornerRadius: CGFloat = 28,
        glow: Color = .clear,
        glowIntensity: Double = 0
    ) -> some View {
        self.glassEffect(
            glow != .clear
                ? Glass.clear.tint(glow.opacity(glowIntensity))
                : .clear,
            in: .rect(cornerRadius: cornerRadius)
        )
    }

    func glassNavBar() -> some View {
        self.glassEffect(.clear, in: .rect(cornerRadius: 0))
    }

    func glassButton(
        glow: Color = .clear,
        glowIntensity: Double = 0
    ) -> some View {
        self.glassEffect(
            glow != .clear
                ? Glass.clear.tint(glow.opacity(glowIntensity))
                : .clear,
            in: .capsule
        )
    }

    func glassFloating(
        cornerRadius: CGFloat = 28,
        glow: Color = .clear,
        glowIntensity: Double = 0
    ) -> some View {
        self.glassEffect(
            glow != .clear
                ? Glass.clear.tint(glow.opacity(glowIntensity))
                : .clear,
            in: .rect(cornerRadius: cornerRadius)
        )
    }

    func glassInput() -> some View {
        self.glassEffect(.clear, in: .rect(cornerRadius: 14))
    }

    func glassTabBar() -> some View {
        self.glassEffect(.clear, in: .rect(cornerRadius: 0))
    }

    func glassStyle(
        cornerRadius: CGFloat = 28,
        glow: Color = .clear,
        glowIntensity: Double = 0
    ) -> some View {
        self.glassEffect(
            glow != .clear
                ? Glass.clear.tint(glow.opacity(glowIntensity))
                : .clear,
            in: .rect(cornerRadius: cornerRadius)
        )
    }

    func glassBar() -> some View {
        self.glassEffect(.clear, in: .rect(cornerRadius: 0))
    }

    func liquidPress(action: @escaping () -> Void) -> some View {
        modifier(LiquidGlassPressModifier(action: action))
    }
}
