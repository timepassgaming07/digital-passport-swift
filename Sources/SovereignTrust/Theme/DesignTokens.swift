import SwiftUI

extension Animation {
    static let stSpring     = Animation.spring(response: 0.40, dampingFraction: 0.80)
    static let stFastSpring = Animation.spring(response: 0.25, dampingFraction: 0.70)
    static let stFloat      = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
    static let stPulse      = Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true)
}

enum BadgeSize {
    case small, medium, large
    var dotSize: CGFloat {
        switch self { case .small: return 5; case .medium: return 7; case .large: return 9 }
    }
    var fontSize: CGFloat {
        switch self { case .small: return 9; case .medium: return 11; case .large: return 13 }
    }
    var hPad: CGFloat {
        switch self { case .small: return 6; case .medium: return 9; case .large: return 13 }
    }
    var vPad: CGFloat {
        switch self { case .small: return 3; case .medium: return 5; case .large: return 7 }
    }
}

struct PulseModifier: ViewModifier {
    let active: Bool
    let color: Color
    @State private var scale: CGFloat = 1
    func body(content: Content) -> some View {
        content
            .scaleEffect(active ? scale : 1)
            .onChange(of: active) { _, val in
                if val { withAnimation(.stPulse) { scale = 1.4 } }
                else { scale = 1 }
            }
    }
}
