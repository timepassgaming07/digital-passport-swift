import SwiftUI

struct TrustEngineView: View {
    @State private var graphTab = 0
    @State private var pipeStep = 0
    @State private var timer: Timer?
    let graphTabs = ["Education","Product","Identity","Network"]

    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    GlassCard(cornerRadius: 28) {
                        VStack(spacing: 12) {
                            Image(systemName: "network")
                                .font(.system(size: 52)).foregroundStyle(Color.stCyan)
                                .shadow(color: Color.stCyan.opacity(0.5), radius: 18)
                            Text("The Trust Engine").font(.stTitle1).foregroundStyle(Color.stPrimary)
                            Text("Decentralised cryptographic trust for everything")
                                .font(.stBodySm).foregroundStyle(Color.stSecondary)
                                .multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity)
                    }

                    TrustConceptCard(number: 1, icon: "lightbulb.fill",
                        title: "The Simple Principle",
                        description: "Every claim — a degree, a product, an identity — can be anchored to a cryptographic proof on a decentralised ledger. Verifiers trust math, not intermediaries.")

                    TrustGraphCard(tabs: graphTabs, selected: $graphTab)
                    VerificationFlowCard(activeStep: pipeStep)
                    UseCaseGrid()
                    TrustNetworkCard()

                    GlassCard(cornerRadius: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("6. The Future of Trust", systemImage: "sparkles")
                                .font(.stHeadline).foregroundStyle(Color.stPurple)
                            Text("A world where identity is self-sovereign. Where credentials follow people, not institutions. Where trust is mathematical, not bureaucratic.")
                                .font(.stBody).foregroundStyle(Color.stSecondary)
                        }
                    }

                    Spacer(minLength: 90)
                }
                .padding(.horizontal, 20).padding(.top, 8)
            }
        }
        .navigationTitle("Trust Engine")

        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { startPipeline() }
        .onDisappear { timer?.invalidate() }
    }

    private func startPipeline() {
        pipeStep = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { _ in
            DispatchQueue.main.async {
                self.pipeStep = self.pipeStep >= 5 ? 0 : self.pipeStep + 1
            }
        }
    }
}
