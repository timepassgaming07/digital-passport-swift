import SwiftUI
struct VerifyView: View {
    @State private var input = ""
    @State private var selected: VerificationSubjectType = .credential
    @State private var engine = VerificationEngine()
    @FocusState private var focused: Bool
    @State private var appState = AppState.shared
    @State private var trustScoreVM = TrustScoreViewModel()
    var body: some View {
        ZStack {
            AmbientBackground(isDark: appState.isDarkMode).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Verify Anything").font(.largeTitle.bold()).foregroundStyle(.white)
                        Text("Paste DID, QR payload or credential ID").font(.subheadline).foregroundStyle(Color.stSecondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    ScanTypeSelector(selected: $selected)
                    GlassCard(cornerRadius: 18, innerPadding: 14, style: .liquid) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Input", systemImage: "text.cursor").font(.caption.weight(.medium)).foregroundStyle(Color.stTertiary)
                            ZStack(alignment: .topLeading) {
                                if input.isEmpty {
                                    Text("did:sov:… or paste QR payload…").font(.system(.caption, design: .monospaced)).foregroundStyle(Color.stQuaternary).allowsHitTesting(false)
                                }
                                TextEditor(text: $input).frame(minHeight: 80, maxHeight: 160).font(.system(.caption, design: .monospaced)).foregroundStyle(.white).scrollContentBackground(.hidden).focused($focused)
                            }
                        }
                    }
                    HStack(spacing: 12) {
                        Button { input = UIPasteboard.general.string ?? "" } label: {
                            Label("Paste", systemImage: "doc.on.clipboard").font(.subheadline).foregroundStyle(Color.stSecondary)
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .glassButton()
                        }
                        Spacer()
                        GlassButton(label: "Verify", icon: "checkmark.seal.fill", isLoading: engine.isRunning) {
                            guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            focused = false
                            Task {
                                await engine.verify(raw: input, type: selected)
                                if let r = engine.result {
                                    trustScoreVM.evaluate(result: r, rawPayload: input)
                                }
                            }
                        }
                    }
                    if engine.isRunning {
                        GlassCard(cornerRadius: 22, innerPadding: 16, style: .liquid) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(engine.steps.enumerated()), id: \.offset) { i, s in
                                    VerificationStepRow(step: s, isLast: i == engine.steps.count - 1)
                                }
                            }
                        }.transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if let r = engine.result, !engine.isRunning {
                        VerificationResultCard(result: r, trustScore: trustScoreVM.score) { engine.result = nil; trustScoreVM.reset() }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 110)
            }
            .scrollContentBackground(.hidden)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Verify")
        .navigationBarTitleDisplayMode(.inline)

        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.stSpring, value: engine.isRunning)
    }
}
