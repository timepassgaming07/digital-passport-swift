import SwiftUI

struct CredentialCard: View {
    let cwi: CredentialWithIssuer
    var trustScore: TrustScore? = nil
    var body: some View {
        GlassCard(cornerRadius:22,glowColor:cwi.credential.trustState.glowColor,glowOpacity:0.08,innerPadding:0,style:.liquid) {
            HStack(spacing:0) {
                // Accent bar
                Rectangle().fill(cwi.credential.trustState.glowColor)
                    .frame(width:3).clipShape(RoundedRectangle(cornerRadius:2))
                    .padding(.vertical,10).padding(.horizontal,12)
                VStack(alignment:.leading,spacing:5) {
                    HStack(spacing:6) {
                        Text(cwi.issuer.logoEmoji).font(.subheadline)
                        Text(cwi.issuer.shortName).font(.caption).foregroundStyle(.white.opacity(0.65))
                    }
                    Text(cwi.credential.title).font(.headline.weight(.semibold)).foregroundStyle(.white)
                    HStack(spacing:8) {
                        Label(cwi.credential.type.label,systemImage:cwi.credential.type.icon)
                            .font(.caption).foregroundStyle(.white.opacity(0.50))
                        TrustBadge(state:cwi.credential.trustState,size:.small)
                        if let ts = trustScore {
                            TrustScoreInline(trustScore: ts)
                        }
                    }
                    if let exp = cwi.credential.expiresAt {
                        Text("Expires \(exp.formatted(style:.medium))")
                            .font(.caption).foregroundStyle(.white.opacity(0.40))
                    }
                }.padding(.vertical,13)
                Spacer()
                Image(systemName:"chevron.right").foregroundStyle(.white.opacity(0.35)).padding(.trailing,14)
            }
        }
    }
}
