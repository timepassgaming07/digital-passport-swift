import SwiftUI

struct IdentityCard: View {
    let identity: Identity; var floatY: CGFloat = 0
    @State private var shimmer: CGFloat = -0.5
    var body: some View {
        GlassCard(cornerRadius:28,glowColor: Color.stCyan,glowOpacity:0.18,innerPadding:0,style:.frost) {
            ZStack {
                RoundedRectangle(cornerRadius:28,style:.continuous)
                    .fill(LinearGradient(
                        colors:[.clear,Color.stCyan.opacity(0.06),Color.stPurple.opacity(0.04),.clear],
                        startPoint:UnitPoint(x:shimmer,y:0),endPoint:UnitPoint(x:shimmer+0.7,y:1)))
                    .allowsHitTesting(false)
                VStack(spacing:0) {
                    HStack(alignment:.center,spacing:16) {
                        ZStack {
                            Circle()
                                .stroke(LinearGradient(colors:[.stCyan,.stPurple],startPoint:.topLeading,endPoint:.bottomTrailing),lineWidth:2)
                                .frame(width:78,height:78).shadow(color: Color.stCyan.opacity(0.5),radius:12)
                            Text(identity.avatarEmoji).font(.system(size:38))
                        }
                        VStack(alignment:.leading,spacing:4) {
                            Text(identity.displayName).font(.title3.weight(.semibold)).foregroundStyle(.white)
                            Text(identity.handle).font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.65))
                            if let lv = identity.lastVerifiedAt {
                                Text("Verified \(Formatters.timeAgo(lv))").font(.caption).foregroundStyle(.white.opacity(0.40))
                            }
                        }
                        Spacer()
                        TrustScoreRing(score:identity.trustScore,size:78)
                    }.padding(18)
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height:0.5)
                    HStack {
                        Label(Formatters.shortDID(identity.did),systemImage:"link")
                            .font(.system(.caption2,design:.monospaced)).foregroundStyle(.white.opacity(0.40)).lineLimit(1)
                        Spacer()
                        Label("Secure Enclave",systemImage:"lock.fill").font(.caption).foregroundStyle(.white.opacity(0.65))
                    }.padding(.horizontal,18).padding(.vertical,11)
                }
            }
        }
        .offset(y:floatY)
        .onAppear { withAnimation(.linear(duration:4).repeatForever(autoreverses:false)) { shimmer=1.5 } }
    }
}
