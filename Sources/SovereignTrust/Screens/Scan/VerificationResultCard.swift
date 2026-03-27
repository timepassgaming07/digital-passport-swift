import SwiftUI

struct VerificationResultCard: View {
    let result: VerificationResult
    var onDismiss: (() -> Void)? = nil
    @State private var layer = 0
    @State private var appeared = false
    @State private var hoverScale: CGFloat = 1.0
    @State private var hoverGlow = false
    @State private var ringProgress: CGFloat = 0

    var body: some View {
        GlassCard(cornerRadius:26,
            glowColor:result.trustState.glowColor,
            glowOpacity:result.trustState.glowOpacity,
            innerPadding:0) {
            VStack(spacing:0) {
                // Animated accent stripe with glow
                ZStack {
                    Rectangle().fill(result.trustState.glowColor).frame(height:3)
                    Rectangle().fill(result.trustState.glowColor.opacity(hoverGlow ? 0.6 : 0.2))
                        .frame(height:3).blur(radius: hoverGlow ? 8 : 2)
                }

                VStack(alignment:.leading, spacing:12) {
                    // Layer 0 — animated trust ring + summary
                    HStack(spacing:14) {
                        // Animated trust ring icon
                        ZStack {
                            Circle()
                                .stroke(result.trustState.glowColor.opacity(0.15), lineWidth: 3)
                                .frame(width:48, height:48)
                            Circle()
                                .trim(from: 0, to: ringProgress)
                                .stroke(result.trustState.glowColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width:48, height:48)
                                .rotationEffect(.degrees(-90))
                            Image(systemName:result.trustState.sfIcon)
                                .foregroundStyle(result.trustState.glowColor)
                                .font(.title3)
                                .scaleEffect(appeared ? 1.0 : 0.3)
                                .opacity(appeared ? 1 : 0)
                        }
                        .shadow(color: result.trustState.glowColor.opacity(hoverGlow ? 0.5 : 0.2), radius: hoverGlow ? 12 : 4)

                        VStack(alignment:.leading, spacing:3) {
                            Text(result.subjectId)
                                .font(.stHeadline).foregroundStyle(Color.stPrimary).lineLimit(1)
                            Text(result.summary).font(.stBodySm).foregroundStyle(Color.stSecondary)
                        }
                        Spacer()
                        VStack(spacing:6) {
                            TrustBadge(state:result.trustState, size:.small)
                            if let dismiss = onDismiss {
                                Button(action:dismiss) {
                                    Image(systemName:"xmark.circle.fill").foregroundStyle(Color.stTertiary)
                                }
                            }
                        }
                    }

                    // Stat chips with stagger
                    HStack(spacing:8) {
                        statChip("✓ \(result.passCount)", color:Color(hex:"00FF88"), delay: 0.1)
                        if result.warnCount > 0 { statChip("⚠ \(result.warnCount)", color: Color.stGold, delay: 0.2) }
                        if result.failCount > 0 { statChip("✗ \(result.failCount)", color: Color.stRed, delay: 0.3) }
                        statChip("\(result.durationMs)ms", color: Color.stSecondary, delay: 0.4)
                    }

                    // Layer 1 — check rows with slide-in
                    if layer >= 1 {
                        Divider().background(Color.white.opacity(0.1))
                        VStack(alignment:.leading, spacing:8) {
                            ForEach(Array(result.checks.enumerated()), id:\.element.id) { idx, c in
                                HStack(spacing:8) {
                                    Image(systemName:c.outcome.icon).foregroundStyle(c.outcome.color).font(.caption2)
                                    Text(c.label).font(.stCaption).foregroundStyle(Color.stPrimary)
                                    Spacer()
                                    if let d = c.detail {
                                        Text(d).font(.stCaption).foregroundStyle(Color.stTertiary).lineLimit(1)
                                    }
                                }
                                .offset(x: appeared ? 0 : 30)
                                .opacity(appeared ? 1 : 0)
                                .animation(.spring(response:0.4, dampingFraction:0.7).delay(Double(idx) * 0.06), value: appeared)
                            }
                        }
                        .transition(.opacity.combined(with:.offset(y:12)))
                    }

                    // Layer 2 — trust chain with connected nodes
                    if layer >= 2 {
                        Divider().background(Color.white.opacity(0.1))
                        trustChain
                            .transition(.opacity.combined(with:.scale(scale: 0.9)))
                    }

                    // Tap hint
                    HStack {
                        Spacer()
                        Image(systemName: layer == 2 ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                        Text(layer==0 ? "tap for details" : layer==1 ? "tap for trust chain" : "tap to collapse")
                            .font(.stCaption).foregroundStyle(Color.stQuaternary)
                    }
                }
                .padding(16)
            }
        }
        .scaleEffect(hoverScale)
        .animation(.spring(response:0.5, dampingFraction:0.7), value: hoverScale)
        .onTapGesture {
            // Hover bounce on tap
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { hoverScale = 0.97 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) { hoverScale = 1.0 }
            }
            withAnimation(.stSpring) { layer = (layer+1) % 3 }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                ringProgress = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                hoverGlow = true
            }
        }
    }

    private func statChip(_ t: String, color: Color, delay: Double = 0) -> some View {
        Text(t).font(.stCaption).foregroundStyle(color)
            .padding(.horizontal,8).padding(.vertical,4)
            .glassButton(glow: color, glowIntensity: 0.12)
            .scaleEffect(appeared ? 1.0 : 0.7)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay), value: appeared)
    }

    private var trustChain: some View {
        HStack(spacing:8) {
            ForEach(Array(result.checks.prefix(3).enumerated()),id:\.offset) { idx,c in
                VStack(spacing:4) {
                    ZStack {
                        Circle()
                            .stroke(c.outcome.color.opacity(0.3), lineWidth:2)
                            .frame(width:36,height:36)
                        Circle()
                            .fill(c.outcome.color.opacity(0.08))
                            .frame(width:36,height:36)
                            .glassEffect(Glass.clear.tint(c.outcome.color.opacity(0.15)), in: .circle)
                        Image(systemName:c.outcome.icon).foregroundStyle(c.outcome.color).font(.caption)
                    }
                    .shadow(color: c.outcome.color.opacity(0.3), radius: 6)
                    Text(c.label).font(.system(size:8,weight:.medium)).foregroundStyle(Color.stTertiary)
                        .multilineTextAlignment(.center).lineLimit(2).frame(width:48)
                }
                .scaleEffect(appeared ? 1.0 : 0.5)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response:0.5, dampingFraction:0.6).delay(Double(idx) * 0.12), value: appeared)
                if idx < 2 {
                    VStack(spacing:2) {
                        ForEach(0..<3, id:\.self) { _ in
                            Circle().fill(Color.white.opacity(0.15)).frame(width:3, height:3)
                        }
                    }
                    .frame(maxWidth:.infinity)
                }
            }
        }
    }
}
