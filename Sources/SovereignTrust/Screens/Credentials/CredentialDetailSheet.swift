import SwiftUI
struct CredentialDetailSheet: View {
    let cwi: CredentialWithIssuer
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage? = nil
    private var c: Credential { cwi.credential }
    private var iss: Issuer   { cwi.issuer }
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:20) {
                    HStack {
                        VStack(alignment:.leading,spacing:2) {
                            Text(c.title).font(.stTitle2).foregroundStyle(Color.stPrimary)
                            Text(iss.name).font(.stBodySm).foregroundStyle(Color.stSecondary)
                        }
                        Spacer()
                        Button{dismiss()} label:{
                            Image(systemName:"xmark.circle.fill").font(.title2).foregroundStyle(Color.stTertiary)
                        }
                    }.padding(.top,8)
                    TrustBadge(state:c.trustState)
                    // QR code
                    if let img = qrImage {
                        GlassCard(cornerRadius:24,innerPadding:20) {
                            VStack(spacing:12) {
                                Image(uiImage:img).interpolation(.none).resizable()
                                    .scaledToFit().frame(width:200,height:200)
                                    .clipShape(RoundedRectangle(cornerRadius:12))
                                Text("Scan to verify").font(.stCaption).foregroundStyle(Color.stSecondary)
                            }.frame(maxWidth:.infinity)
                        }
                    }
                    // Issuer row
                    GlassCard(cornerRadius:22) {
                        HStack(spacing:12) {
                            Text(iss.logoEmoji).font(.title2)
                            VStack(alignment:.leading,spacing:2) {
                                Text(iss.name).font(.stHeadline).foregroundStyle(Color.stPrimary)
                                Text(iss.category.capitalized).font(.stCaption).foregroundStyle(Color.stSecondary)
                            }
                            Spacer()
                            TrustBadge(state:iss.trustState,size:.small)
                        }
                    }
                    // Details
                    GlassCard(cornerRadius:22) {
                        VStack(alignment:.leading,spacing:12) {
                            detailRow("Issued", c.issuedAt.formatted(style:.medium))
                            if let e = c.expiresAt { detailRow("Expires", e.formatted(style:.medium)) }
                            detailRow("Status", c.status.rawValue.capitalized)
                            detailRow("Hash", Formatters.shortHash(c.hash))
                            detailRow("Issuer DID", Formatters.shortDID(c.issuerDid))
                        }
                    }
                    GlassButton(label:"Share QR Code",icon:"square.and.arrow.up") { shareQR() }
                    Spacer(minLength:40)
                }
                .padding(.horizontal,20)
            }
        }
        .onAppear { qrImage = QRGeneratorService.generate(from:QRGeneratorService.credentialPayload(c)) }
    }
    private func detailRow(_ l:String,_ v:String) -> some View {
        VStack(alignment:.leading,spacing:2) {
            Text(l).font(.stCaption).foregroundStyle(Color.stTertiary)
            Text(v).font(.stMono).foregroundStyle(Color.stSecondary).lineLimit(2)
        }
    }
    private func shareQR() {
        guard let img = qrImage else { return }
        let ac = UIActivityViewController(activityItems:[img],applicationActivities:nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(ac,animated:true)
        }
    }
}
