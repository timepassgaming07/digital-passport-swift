import SwiftUI
struct CredentialListView: View {
    @Bindable var vm: CredentialViewModel
    let identity: Identity
    @State private var credentialScores: [String: TrustScore] = [:]
    var body: some View {
        VStack(alignment:.leading, spacing:12) {
            HStack {
                Text("Credentials").font(.stHeadline).foregroundStyle(Color.stPrimary)
                Spacer()
                Text("\(vm.items.count) verified").font(.stCaption).foregroundStyle(Color.stSecondary)
            }
            CredentialFilterBar(active:$vm.activeFilter) { vm.applyFilter($0) }
            if vm.isLoading {
                LoadingState(message:"Loading credentials…")
            } else if vm.filtered.isEmpty {
                EmptyState(icon:"checkmark.seal",title:"No credentials",message:"No credentials match this filter")
            } else {
                LazyVStack(spacing:12) {
                    ForEach(vm.filtered) { cwi in
                        CredentialCard(cwi:cwi, trustScore: credentialScores[cwi.credential.id])
                            .glassPress { vm.selected = cwi }
                            .task { await evaluateIfNeeded(cwi) }
                    }
                }
            }
        }
        .sheet(item:$vm.selected) { cwi in CredentialDetailSheet(cwi:cwi) }
    }

    private func evaluateIfNeeded(_ cwi: CredentialWithIssuer) async {
        guard credentialScores[cwi.credential.id] == nil else { return }
        let score = await TrustScoreService.shared.evaluateCredential(cwi.credential, issuer: cwi.issuer)
        credentialScores[cwi.credential.id] = score
    }
}
