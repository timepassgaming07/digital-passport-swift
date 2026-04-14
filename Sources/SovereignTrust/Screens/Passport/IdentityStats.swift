import SwiftUI
struct IdentityStats: View {
    let identity: Identity; let credCount: Int
    var body: some View {
        HStack(spacing:12) {
            stat("\(credCount)", "Credentials", "◈")
            stat(identity.trustState.label, "Trust State", "🧠")
            stat(identity.biometryType.rawValue, "Biometry", "🔐")
        }
    }
    private func stat(_ v:String,_ l:String,_ i:String) -> some View {
        GlassCard(cornerRadius:20,innerPadding:14) {
            VStack(alignment:.leading,spacing:4) {
                Text(i).font(.title2)
                Text(v).font(.stTitle2).foregroundStyle(Color.stCyan)
                Text(l).font(.stCaption).foregroundStyle(Color.stSecondary)
            }.frame(maxWidth:.infinity,alignment:.leading)
        }
    }
}
