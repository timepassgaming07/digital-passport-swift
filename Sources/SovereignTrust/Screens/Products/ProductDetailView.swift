import SwiftUI
struct ProductDetailView: View {
    let product: Product
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:20) {
                    GlassCard(cornerRadius:28,glowColor:product.trustState.glowColor,glowOpacity:0.22) {
                        VStack(alignment:.leading,spacing:12) {
                            HStack {
                                VStack(alignment:.leading,spacing:4) {
                                    Text(product.brand).font(.stCaption).foregroundStyle(Color.stSecondary)
                                    Text(product.name).font(.stTitle2).foregroundStyle(Color.stPrimary)
                                    Text(product.category).font(.stBodySm).foregroundStyle(Color.stTertiary)
                                }
                                Spacer()
                                TrustBadge(state:product.trustState)
                            }
                            Divider().background(Color.white.opacity(0.1))
                            HStack { Text("SN").font(.stCaption).foregroundStyle(Color.stTertiary); Spacer()
                                Text(product.serialNumber).font(.stMono).foregroundStyle(Color.stSecondary) }
                            HStack { Text("Manufactured").font(.stCaption).foregroundStyle(Color.stTertiary); Spacer()
                                Text(product.manufacturedAt.formatted(style:.medium)).font(.stCaption).foregroundStyle(Color.stSecondary) }
                        }
                    }
                    CustodyChainView(chain:product.custodyChain)
                    Spacer(minLength:90)
                }
                .padding(.horizontal,20).padding(.top,8)
            }
        }
        .navigationTitle(product.name)
        .toolbarBackground(.ultraThinMaterial,for:.navigationBar)
        .toolbarColorScheme(.dark,for:.navigationBar)
    }
}
