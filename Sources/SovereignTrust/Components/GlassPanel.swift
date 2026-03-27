import SwiftUI

// MARK: - Glass Floating Panel
/// A floating overlay panel with native liquid glass.
struct GlassFloatingPanel<Content: View>: View {
    var cornerRadius: CGFloat = 28
    var glowColor: Color = .clear
    var glowIntensity: Double = 0
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(20)
            .glassEffect(
                glowColor != .clear
                    ? Glass.clear.tint(glowColor.opacity(glowIntensity))
                    : .clear,
                in: .rect(cornerRadius: cornerRadius)
            )
    }
}

// MARK: - Glass Navigation Bar Background
struct GlassNavBarBackground: View {
    var body: some View {
        Rectangle()
            .fill(.clear)
            .glassEffect(.clear, in: .rect(cornerRadius: 0))
            .ignoresSafeArea()
    }
}

// MARK: - Glass Tab Bar Background
struct GlassTabBarBackground: View {
    var body: some View {
        Rectangle()
            .fill(.clear)
            .glassEffect(.clear, in: .rect(cornerRadius: 0))
            .ignoresSafeArea()
    }
}

// MARK: - Glass Section Header
/// A subtle section header with glass styling.
struct GlassSectionHeader: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.stCyan)
            }
            Text(title)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(Color.white.opacity(0.55))
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Glass Divider
/// A subtle divider matching the glass aesthetic.
struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.0),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }
}

// MARK: - Glass Chip / Pill
/// A small tag-like component with glass background.
struct GlassChip: View {
    let label: String
    var icon: String? = nil
    var color: Color = .stCyan
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
            }
            Text(label)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(isActive ? color : Color.white.opacity(0.65))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glassEffect(
            isActive ? Glass.clear.tint(color.opacity(0.30)) : .clear,
            in: .capsule
        )
    }
}
