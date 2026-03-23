import SwiftUI

struct RecentVerificationsSection: View {
    let results:[VerificationResult]
    var body: some View {
        VStack(alignment:.leading, spacing:12) {
            Text("Recent").font(.stHeadline).foregroundStyle(Color.stPrimary)
            if results.isEmpty {
                GlassCard(cornerRadius:20, innerPadding:20) {
                    EmptyState(icon:"checkmark.seal",
                        title:"No verifications yet",
                        message:"Scan a QR code to get started")
                }
            } else {
                ScrollView(.horizontal, showsIndicators:false) {
                    HStack(spacing:12) {
                        ForEach(results) { r in
                            GlassCard(cornerRadius:20,
                                glowColor:r.trustState.glowColor, glowOpacity:0.12,
                                innerPadding:14) {
                                VStack(alignment:.leading, spacing:8) {
                                    TrustBadge(state:r.trustState, size:.small)
                                    Text(r.subjectId).font(.stHeadline).foregroundStyle(Color.stPrimary).lineLimit(1)
                                    Text(Formatters.timeAgo(r.verifiedAt))
                                        .font(.stCaption).foregroundStyle(Color.stSecondary)
                                }
                                .frame(width:160)
                            }
                        }
                    }
                }
            }
        }
    }
}
