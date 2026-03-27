import SwiftUI

struct IdentityCard: View {
    let identity: Identity; var floatY: CGFloat = 0
    var body: some View {
        GlassCard(cornerRadius:28,innerPadding:0,style:.liquid) {
            VStack(spacing:0) {
                HStack(alignment:.center,spacing:16) {
                    ZStack {
                        Circle()
                            .stroke(LinearGradient(colors:[.stCyan,.stPurple],startPoint:.topLeading,endPoint:.bottomTrailing),lineWidth:2)
                            .frame(width:68,height:68)
                        Text(identity.avatarEmoji).font(.system(size:32))
                    }
                    VStack(alignment:.leading,spacing:4) {
                        Text(identity.displayName).font(.title3.weight(.semibold)).foregroundStyle(.white)
                        Text(identity.handle).font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.65))
                        if let lv = identity.lastVerifiedAt {
                            Text("Verified \(Formatters.timeAgo(lv))").font(.caption).foregroundStyle(.white.opacity(0.40))
                        }
                    }
                    Spacer()
                    TrustScoreRing(score:identity.trustScore,size:68)
                }.padding(16)
                GlassDivider()
                HStack {
                    Label(Formatters.shortDID(identity.did),systemImage:"link")
                        .font(.system(.caption2,design:.monospaced)).foregroundStyle(.white.opacity(0.40)).lineLimit(1)
                    Spacer()
                    Label("Secure Enclave",systemImage:"lock.fill").font(.caption).foregroundStyle(.white.opacity(0.65))
                }.padding(.horizontal,16).padding(.vertical,10)
            }
        }
        .offset(y:floatY)
    }
}
