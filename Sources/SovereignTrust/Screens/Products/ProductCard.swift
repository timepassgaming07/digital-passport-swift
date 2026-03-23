import SwiftUI
struct ProductCard: View {
    let product: Product
    var body: some View {
        GlassCard(cornerRadius:24,glowColor:product.trustState.glowColor,glowOpacity:0.10,innerPadding:0) {
            HStack(spacing:0) {
                Rectangle().fill(product.trustState.glowColor).frame(width:4)
                    .clipShape(RoundedRectangle(cornerRadius:2)).padding(.vertical,12).padding(.horizontal,12)
                VStack(alignment:.leading,spacing:5) {
                    Text(product.brand).font(.stCaption).foregroundStyle(Color.stSecondary)
                    Text(product.name).font(.stHeadline).foregroundStyle(Color.stPrimary)
                    HStack(spacing:8) {
                        Label(product.category,systemImage:"shippingbox").font(.stCaption).foregroundStyle(Color.stTertiary)
                        TrustBadge(state:product.trustState,size:.small)
                    }
                    Text("SN: \(product.serialNumber)").font(.stMonoSm).foregroundStyle(Color.stTertiary)
                }
                .padding(.vertical,14)
                Spacer()
                Image(systemName:product.statusIcon).font(.title3)
                    .foregroundStyle(product.trustState.glowColor).padding(.trailing,16)
            }
        }
    }
}
