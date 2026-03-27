import SwiftUI

struct ScanTypeSelector: View {
    @Binding var selected: VerificationSubjectType
    private let types: [(VerificationSubjectType,String,String)] = [
        (.credential,"Credential","checkmark.seal"),
        (.product,"Product","shippingbox"),
        (.document,"Document","doc.text"),
        (.login,"Login","person.badge.key"),
        (.did,"DID","link"),
    ]
    var body: some View {
        GlassCard(cornerRadius:22, innerPadding:10) {
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:8) {
                    ForEach(types,id:\.0) { type,label,icon in
                        Button { selected = type } label: {
                            Label(label,systemImage:icon)
                                .font(.stCaption)
                                .foregroundStyle(selected==type ? Color.stCyan : Color.stSecondary)
                                .padding(.horizontal,12).padding(.vertical,8)
                                .glassButton(glow: selected==type ? Color.stCyan : .clear, glowIntensity: selected==type ? 0.30 : 0)
                                .overlay(Capsule().stroke(
                                    selected==type ? Color.stCyan.opacity(0.50) : Color.white.opacity(0.12),
                                    lineWidth:1))
                        }
                        .buttonStyle(.plain)
                        .animation(.stFastSpring, value:selected)
                    }
                }
            }
        }
    }
}
