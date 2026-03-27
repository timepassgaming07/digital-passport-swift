import SwiftUI

struct VerificationResultCard: View {
    let result: VerificationResult
    var onDismiss: (() -> Void)? = nil
    @State private var layer = 0

    var body: some View {
        GlassCard(cornerRadius:26,
            glowColor:result.trustState.glowColor,
            glowOpacity:result.trustState.glowOpacity,
            innerPadding:0) {
            VStack(spacing:0) {
                // Accent stripe
                Rectangle().fill(result.trustState.glowColor).frame(height:3)
                VStack(alignment:.leading, spacing:12) {
                    // Layer 0 — always visible
                    HStack {
                        Image(systemName:result.trustState.sfIcon)
                            .foregroundStyle(result.trustState.glowColor).font(.title3)
                        Text(result.subjectId)
                            .font(.stHeadline).foregroundStyle(Color.stPrimary).lineLimit(1)
                        Spacer()
                        TrustBadge(state:result.trustState, size:.small)
                        if let dismiss = onDismiss {
                            Button(action:dismiss) {
                                Image(systemName:"xmark.circle.fill").foregroundStyle(Color.stTertiary)
                            }
                        }
                    }
                    Text(result.summary).font(.stBodySm).foregroundStyle(Color.stSecondary)
                    HStack(spacing:8) {
                        statChip("✓ \(result.passCount)", color:Color(hex:"00FF88"))
                        if result.warnCount > 0 { statChip("⚠ \(result.warnCount)", color: Color.stGold) }
                        if result.failCount > 0 { statChip("✗ \(result.failCount)", color: Color.stRed) }
                        statChip("\(result.durationMs)ms", color: Color.stSecondary)
                    }
                    // Layer 1 — check rows
                    if layer >= 1 {
                        Divider().background(Color.white.opacity(0.1))
                        VStack(alignment:.leading, spacing:8) {
                            ForEach(result.checks) { c in
                                HStack(spacing:8) {
                                    Image(systemName:c.outcome.icon).foregroundStyle(c.outcome.color).font(.caption2)
                                    Text(c.label).font(.stCaption).foregroundStyle(Color.stPrimary)
                                    Spacer()
                                    if let d = c.detail {
                                        Text(d).font(.stCaption).foregroundStyle(Color.stTertiary).lineLimit(1)
                                    }
                                }
                            }
                        }
                        .transition(.opacity.combined(with:.offset(y:12)))
                    }
                    // Layer 2 — trust chain
                    if layer >= 2 {
                        Divider().background(Color.white.opacity(0.1))
                        trustChain
                            .transition(.opacity.combined(with:.offset(y:12)))
                    }
                    // Tap hint
                    HStack {
                        Spacer()
                        Text(layer==0 ? "↓ tap for details" : layer==1 ? "↓ tap for trust chain" : "↑ tap to collapse")
                            .font(.stCaption).foregroundStyle(Color.stQuaternary)
                    }
                }
                .padding(16)
            }
        }
        .onTapGesture { withAnimation(.stSpring) { layer = (layer+1)%3 } }
        .onAppear { layer = 0 }
    }

    private func statChip(_ t:String, color:Color) -> some View {
        Text(t).font(.stCaption).foregroundStyle(color)
            .padding(.horizontal,8).padding(.vertical,4)
            .glassButton(glow: color, glowIntensity: 0.12)
    }

    private var trustChain: some View {
        HStack(spacing:8) {
            ForEach(Array(result.checks.prefix(3).enumerated()),id:\.offset) { idx,c in
                VStack(spacing:4) {
                    ZStack {
                        Circle().stroke(c.outcome.color.opacity(0.5),lineWidth:1.5).frame(width:32,height:32)
                        Image(systemName:c.outcome.icon).foregroundStyle(c.outcome.color).font(.caption)
                    }
                    Text(c.label).font(.system(size:8,weight:.medium)).foregroundStyle(Color.stTertiary)
                        .multilineTextAlignment(.center).lineLimit(2).frame(width:48)
                }
                if idx < 2 {
                    Rectangle().fill(Color.white.opacity(0.15)).frame(height:1).frame(maxWidth:.infinity)
                }
            }
        }
    }
}
