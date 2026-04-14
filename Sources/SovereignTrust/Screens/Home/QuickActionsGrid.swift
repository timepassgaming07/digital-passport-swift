import SwiftUI

struct QuickActionsGrid: View {
    let identity: Identity
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            Text("Quick Actions").font(.headline.weight(.semibold)).foregroundStyle(.white)
            LazyVGrid(columns:[GridItem(.flexible(),spacing:12),GridItem(.flexible(),spacing:12)],spacing:12) {
                ActionTile(title:"Scan QR",  sub:"Verify anything", icon:"qrcode.viewfinder",         dest:AnyView(ScanView()))
                ActionTile(title:"Verify",   sub:"Manual check",    icon:"checkmark.seal.fill",        dest:AnyView(VerifyView()))
                ActionTile(title:"Product Auth", sub:"Scan & claim", icon:"shippingbox.and.arrow.backward.fill", dest:AnyView(ProductAuthView()))
                ActionTile(title:"My Wallet", sub:"Owned products", icon:"wallet.bifold.fill",         dest:AnyView(ProductWalletView()))
                ActionTile(title:"File Request", sub:"Requester/holder QR", icon:"doc.text.viewfinder", dest:AnyView(DocumentRequestWorkflowView()))
            }
        }
    }
}

struct ActionTile: View {
    let title:String; let sub:String; let icon:String; let dest:AnyView
    var body: some View {
        NavigationLink(destination:dest) {
            // LIQUID glass — orbs visible through tile
            GlassCard(cornerRadius:20,innerPadding:16,style:.liquid) {
                VStack(alignment:.leading,spacing:8) {
                    Image(systemName:icon).font(.title2).foregroundStyle(Color.stCyan)
                        .shadow(color: Color.stCyan.opacity(0.4),radius:6)
                    Spacer()
                    Text(title).font(.headline.weight(.semibold)).foregroundStyle(.white)
                    Text(sub).font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.65))
                }
                .frame(maxWidth:.infinity,alignment:.leading)
                .frame(height:100)
            }
        }
        .buttonStyle(.plain)
    }
}
