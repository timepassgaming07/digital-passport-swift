import SwiftUI

struct PostCard: View {
    let post: Post
    let isExpanded: Bool
    let showFraud: Bool
    let onTap: () -> Void

    var body: some View {
        GlassCard(cornerRadius:22,
            glowColor:post.trustState.glowColor,
            glowOpacity:post.trustState == .suspicious ? 0.18 : 0.04,
            innerPadding:0,
            style:.liquid) {
            VStack(alignment:.leading,spacing:0) {
                // Accent stripe
                Rectangle().fill(post.trustState.glowColor).frame(height:2.5)
                VStack(alignment:.leading,spacing:12) {
                    AuthorBadge(author:post.author,showDid:isExpanded)
                    Text(post.content)
                        .font(.body).foregroundStyle(.white.opacity(0.90))
                        .lineLimit(isExpanded ? nil : 3)
                    ClaimBar(verified:post.verifiedClaimCount,total:post.claimCount)
                    if isExpanded && !showFraud {
                        tagsRow.transition(.opacity.combined(with:.offset(y:8)))
                    }
                    if showFraud, let fa = post.fraudAnalysis {
                        fraudSection(fa).transition(.opacity.combined(with:.offset(y:8)))
                    }
                    footerRow
                    Text(showFraud ? "↑ collapse" : isExpanded ? "↓ fraud signals" : "↓ details")
                        .font(.caption).foregroundStyle(.white.opacity(0.30))
                        .frame(maxWidth:.infinity,alignment:.trailing)
                }.padding(14)
            }
        }
        .onTapGesture(perform:onTap)
    }

    private var tagsRow: some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:6) {
                ForEach(post.tags,id:\.self) { tag in
                    Text("#\(tag)").font(.caption).foregroundStyle(Color.stCyan)
                        .padding(.horizontal,8).padding(.vertical,4)
                        .background(.ultraThinMaterial,in:Capsule())
                        .overlay(Capsule().stroke(Color.stCyan.opacity(0.3),lineWidth:0.6))
                }
            }
        }
    }

    private func fraudSection(_ fa: FraudAnalysis) -> some View {
        VStack(alignment:.leading,spacing:8) {
            HStack {
                Text("AI Fraud Analysis").font(.caption).foregroundStyle(.white.opacity(0.60))
                Spacer()
                Text("Risk: \(fa.riskScore)/100").font(.caption2.weight(.bold))
                    .foregroundStyle(fa.riskScore > 60 ? Color(hex:"FF3355") : Color(hex:"FFD60A"))
                    .padding(.horizontal,8).padding(.vertical,3)
                    .background(.ultraThinMaterial,in:Capsule())
            }
            ForEach(fa.signals) { sig in FraudSignalBadge(signal:sig) }
        }
    }

    private var footerRow: some View {
        HStack {
            if let src = post.sourceName {
                Label(src,systemImage:"link").font(.caption).foregroundStyle(.white.opacity(0.40))
            }
            Spacer()
            Text(Formatters.timeAgo(post.publishedAt)).font(.caption).foregroundStyle(.white.opacity(0.40))
        }
    }
}
