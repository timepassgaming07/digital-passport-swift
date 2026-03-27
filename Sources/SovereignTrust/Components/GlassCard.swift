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
    @ViewBuilder let content: () -> Content

    var body: some View {
        let glassStyle: Glass = glowColor != .clear
            ? .clear.tint(glowColor.opacity(glowOpacity))
            : .clear
        content()
            .padding(innerPadding)
            .glassEffect(glassStyle, in: .rect(cornerRadius: cornerRadius))
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
