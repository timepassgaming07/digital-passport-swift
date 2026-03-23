import SwiftUI

struct WalletSummaryCard: View {
    let identity: Identity
    var floatY: CGFloat = 0
    @State private var shimmer: CGFloat = -0.5

    var body: some View {
        // FROST glass — hero card, slightly more opaque for readability
        GlassCard(cornerRadius:28, glowColor: Color.stCyan, glowOpacity:0.20, innerPadding:0, style:.frost) {
            ZStack {
                // Shimmer overlay — holographic effect
                RoundedRectangle(cornerRadius:28,style:.continuous)
                    .fill(LinearGradient(
                        colors:[.clear,Color.stCyan.opacity(0.06),Color.stPurple.opacity(0.04),.clear],
                        startPoint:UnitPoint(x:shimmer,y:0),
                        endPoint:UnitPoint(x:shimmer+0.7,y:1)))
                    .allowsHitTesting(false)

                VStack(spacing:0) {
                    HStack(alignment:.center,spacing:16) {
                        ZStack {
                            Circle()
                                .stroke(LinearGradient(
                                    colors:[.stCyan,.stPurple],
                                    startPoint:.topLeading,endPoint:.bottomTrailing),lineWidth:2)
                                .frame(width:74,height:74)
                                .shadow(color: Color.stCyan.opacity(0.5),radius:10)
                            Text(identity.avatarEmoji).font(.system(size:36))
                        }
                        VStack(alignment:.leading,spacing:4) {
                            Text(identity.displayName).font(.title3.weight(.semibold)).foregroundStyle(.white)
                            Text(identity.handle).font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.65))
                            Text(Formatters.shortDID(identity.did))
                                .font(.system(.caption2,design:.monospaced))
                                .foregroundStyle(.white.opacity(0.40)).lineLimit(1)
                        }
                        Spacer()
                        TrustScoreRing(score:identity.trustScore,size:74)
                    }
                    .padding(18)

                    Rectangle().fill(Color.white.opacity(0.08)).frame(height:0.5)

                    HStack {
                        Image(systemName:"lock.fill").foregroundStyle(.white.opacity(0.5)).font(.caption)
                        Text("Secure Enclave").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.65))
                        Spacer()
                        TrustBadge(state:identity.trustState,size:.small)
                    }
                    .padding(.horizontal,18).padding(.vertical,11)
                }
            }
        }
        .offset(y:floatY)
        .onAppear {
            withAnimation(.linear(duration:4).repeatForever(autoreverses:false)) { shimmer = 1.5 }
        }
    }
}
