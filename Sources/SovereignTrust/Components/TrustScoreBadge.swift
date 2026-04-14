import SwiftUI

// MARK: – Trust Score Badge — Compact ML Trust Indicator

/// Color-coded trust score badge with optional expandable reasons.
/// Green = safe, Yellow = caution, Red = risky.
struct TrustScoreBadge: View {
    let trustScore: TrustScore
    var compact: Bool = true
    var showReasons: Bool = false

    @State private var expanded = false
    @State private var appeared = false

    private var badgeColor: Color { Color(hex: trustScore.riskLevel.color) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Main badge
            HStack(spacing: 6) {
                // Animated ring
                ZStack {
                    Circle()
                        .stroke(badgeColor.opacity(0.2), lineWidth: 2)
                        .frame(width: compact ? 22 : 28, height: compact ? 22 : 28)
                    Circle()
                        .trim(from: 0, to: appeared ? CGFloat(trustScore.score) / 100.0 : 0)
                        .stroke(badgeColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: compact ? 22 : 28, height: compact ? 22 : 28)
                        .rotationEffect(.degrees(-90))
                    Text("\(trustScore.score)")
                        .font(.system(size: compact ? 8 : 10, weight: .bold, design: .rounded))
                        .foregroundStyle(badgeColor)
                }
                .shadow(color: badgeColor.opacity(0.4), radius: 4)

                if !compact {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("TRUST SCORE").font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(badgeColor.opacity(0.7))
                            .tracking(0.8)
                        Text(trustScore.riskLevel.label)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(badgeColor)
                    }
                }
            }
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 4 : 6)
            .glassEffect(Glass.clear.tint(badgeColor.opacity(0.18)), in: .capsule)
            .onTapGesture {
                if showReasons {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        expanded.toggle()
                    }
                }
            }

            // Expandable reasons (debug / detail mode)
            if showReasons && expanded {
                reasonsView
                    .transition(.opacity.combined(with: .offset(y: -8)))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var reasonsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(trustScore.reasons.prefix(5)) { reason in
                HStack(spacing: 6) {
                    Circle()
                        .fill(severityColor(reason.severity))
                        .frame(width: 5, height: 5)
                    Text(reason.signal)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .glassEffect(Glass.clear.tint(badgeColor.opacity(0.08)), in: .rect(cornerRadius: 10))
    }

    private func severityColor(_ s: ReasonSeverity) -> Color {
        switch s {
        case .positive: return Color(hex: "00FF88")
        case .neutral:  return Color(hex: "8E8E93")
        case .warning:  return Color(hex: "FFD60A")
        case .critical: return Color(hex: "FF3355")
        }
    }
}

// MARK: – Inline Trust Score (for cards — ultra-compact)

/// Minimal inline indicator: just the score number with color dot.
struct TrustScoreInline: View {
    let trustScore: TrustScore

    private var badgeColor: Color { Color(hex: trustScore.riskLevel.color) }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: 5, height: 5)
                .shadow(color: badgeColor.opacity(0.6), radius: 3)
            Text("\(trustScore.score)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .glassEffect(Glass.clear.tint(badgeColor.opacity(0.15)), in: .capsule)
    }
}
