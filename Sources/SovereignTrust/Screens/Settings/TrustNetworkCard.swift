import SwiftUI
struct TrustNetworkCard: View {
    private let items = [("🏛️","Issuers","9+"),("👛","Wallets","12K+"),("🔍","Verifiers","340+"),("🏢","Institutions","89+")]
    var body: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading,spacing:12) {
                Label("5. Trust Network",systemImage:"person.3.fill").font(.stHeadline).foregroundStyle(Color.stCyan)
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10) {
                    ForEach(items,id:\.1) { (e,t,n) in
                        VStack(alignment:.leading,spacing:4) {
                            HStack { Text(e).font(.title3); Spacer(); Text(n).font(.stTitle3).foregroundStyle(Color.stCyan) }
                            Text(t).font(.stHeadline).foregroundStyle(Color.stPrimary)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:14))
                        .overlay(RoundedRectangle(cornerRadius:14).stroke(Color.white.opacity(0.08),lineWidth:1))
                    }
                }
            }
        }
    }
}
