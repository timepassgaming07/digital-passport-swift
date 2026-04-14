import SwiftUI

struct WalletSummaryCard: View {
    let identity: Identity
    var floatY: CGFloat = 0

    var body: some View {
        GlassCard(cornerRadius:28, innerPadding:0, style:.liquid) {
            VStack(spacing:0) {
                HStack(alignment:.center,spacing:16) {
                    ZStack {
                        Circle()
                            .stroke(LinearGradient(
                                colors:[.stCyan,.stPurple],
                                startPoint:.topLeading,endPoint:.bottomTrailing),lineWidth:2)
                            .frame(width:68,height:68)
                        Text(identity.avatarEmoji).font(.system(size:32))
                    }
                    VStack(alignment:.leading,spacing:4) {
                        Text(identity.displayName).font(.title3.weight(.semibold)).foregroundStyle(.white)
                        Text(identity.handle).font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.65))
                        Text(Formatters.shortDID(identity.did))
                            .font(.system(.caption2,design:.monospaced))
                            .foregroundStyle(.white.opacity(0.40)).lineLimit(1)
                    }
                    Spacer()
                    TrustBadge(state: identity.trustState, size: .small)
                }
                .padding(16)

                GlassDivider()

                HStack {
                    Image(systemName:"lock.fill").foregroundStyle(.white.opacity(0.5)).font(.caption)
                    Text("Secure Enclave").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.65))
                    Spacer()
                    TrustBadge(state:identity.trustState,size:.small)
                }
                .padding(.horizontal,16).padding(.vertical,10)
            }
        }
        .offset(y:floatY)
    }
}
