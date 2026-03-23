import SwiftUI
struct HandshakeView: View {
    let handshake: Handshake
    @Environment(\.dismiss) private var dismiss
    @State private var vm = HandshakeViewModel()

    var body: some View {
        ZStack {
            AmbientBackground()
            VStack(spacing:24) {
                Spacer()
                VStack(spacing:10) {
                    Image(systemName:"person.badge.key.fill").font(.system(size:52))
                        .foregroundStyle(Color.stCyan).shadow(color: Color.stCyan.opacity(0.5),radius:18)
                    Text("Login Request").font(.stTitle1).foregroundStyle(Color.stPrimary)
                    Text("DID Authentication Challenge").font(.stBodySm).foregroundStyle(Color.stSecondary)
                }
                GlassCard(cornerRadius:28, glowColor: Color.stBlue, glowOpacity:0.20) {
                    VStack(alignment:.leading, spacing:14) {
                        HStack {
                            Text(handshake.challenge.service).font(.stTitle2).foregroundStyle(Color.stPrimary)
                            Spacer()
                            Text("\(vm.timeRemaining)s")
                                .font(.stCaption).foregroundStyle(vm.timeRemaining < 60 ? Color.stRed : Color.stSecondary)
                                .padding(.horizontal,10).padding(.vertical,5)
                                .background(.ultraThinMaterial,in:Capsule())
                        }
                        VStack(alignment:.leading, spacing:2) {
                            Text("Nonce").font(.stCaption).foregroundStyle(Color.stTertiary)
                            Text(String(handshake.challenge.nonce.prefix(32)) + "…")
                                .font(.stMono).foregroundStyle(Color.stSecondary)
                        }
                        Text("This service is requesting DID authentication")
                            .font(.stBodySm).foregroundStyle(Color.stSecondary)
                        HStack(spacing:8) {
                            scopeChip("● Read Identity")
                            scopeChip("● Share DID")
                            scopeChip("● Sign Nonce")
                        }
                    }
                }
                // Result
                if let h = vm.handshake, h.status == .verified || h.status == .rejected {
                    let ok = h.status == .verified
                    GlassCard(cornerRadius:24,
                        glowColor:ok ? Color(hex:"00FF88") : Color.stRed, glowOpacity:0.40) {
                        HStack(spacing:12) {
                            Image(systemName:ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title2).foregroundStyle(ok ? Color(hex:"00FF88") : Color.stRed)
                            Text(ok ? "Authentication Complete" : "Authentication Failed")
                                .font(.stHeadline).foregroundStyle(Color.stPrimary)
                        }.frame(maxWidth:.infinity)
                    }
                }
                if let err = vm.error {
                    Text(err).font(.stCaption).foregroundStyle(Color.stRed)
                        .padding(12).background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:12))
                }
                Spacer()
                VStack(spacing:12) {
                    let h = vm.handshake ?? handshake
                    if h.status == .pending {
                        GlassButton(label:"Sign with \(handshake.challenge.service.isEmpty ? "Face ID" : "Face ID")",
                            icon:"faceid", variant:.primary, isLoading:vm.isSigning, fullWidth:true) {
                            Task { await vm.signWithBiometrics() }
                        }
                    }
                    GlassButton(label:"Cancel",icon:"xmark",variant:.secondary,fullWidth:true) { dismiss() }
                }
                .padding(.horizontal,24).padding(.bottom,40)
            }
            .padding(.horizontal,24)
        }
        .onAppear { vm.present(handshake) }
    }

    private func scopeChip(_ t:String) -> some View {
        Text(t).font(.stCaption).foregroundStyle(Color.stSecondary)
            .padding(.horizontal,10).padding(.vertical,5)
            .background(.ultraThinMaterial,in:Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15),lineWidth:1))
    }
}
