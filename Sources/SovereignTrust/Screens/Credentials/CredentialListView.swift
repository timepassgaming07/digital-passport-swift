import SwiftUI
struct CredentialListView: View {
    @Bindable var vm: CredentialViewModel
    let identity: Identity
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
                        CredentialCard(cwi:cwi)
                            .glassPress { vm.selected = cwi }
                    }
                }
            }
        }
        .sheet(item:$vm.selected) { cwi in CredentialDetailSheet(cwi:cwi) }
    }
}
