import SwiftUI
struct PassportView: View {
    let identity: Identity
    @State private var vm = CredentialViewModel()
    @State private var floatY: CGFloat = 0
    var body: some View {
        ZStack {
            AmbientBackground(isDark: true).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    IdentityCard(identity: identity, floatY: floatY)
                    IdentityStats(identity: identity, credCount: vm.items.count)
                    CredentialListView(vm: vm, identity: identity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 110)
            }
            .scrollContentBackground(.hidden)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Passport")
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load(subjectDid: identity.did) }
        .onAppear { withAnimation(.stFloat) { floatY = 3 } }
    }
}
