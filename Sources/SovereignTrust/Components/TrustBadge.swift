import SwiftUI

struct TrustBadge: View {
    let state: TrustState
    var showPulse: Bool = false
    var size: BadgeSize = .medium

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(state.glowColor)
                .frame(width: size.dotSize, height: size.dotSize)
                .shadow(color: state.glowColor.opacity(0.9), radius: 4)
                .modifier(PulseModifier(active: showPulse && state == .pending, color: state.glowColor))
            Text(state.label.uppercased())
                .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(state.glowColor)
        }
        .padding(.horizontal, size.hPad)
        .padding(.vertical, size.vPad)
        .glassEffect(Glass.clear.tint(state.glowColor.opacity(0.30)), in: .capsule)
    }
}
