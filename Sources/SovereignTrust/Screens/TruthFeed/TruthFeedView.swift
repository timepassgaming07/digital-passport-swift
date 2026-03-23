import SwiftUI
struct TruthFeedView: View {
    @State private var vm = TruthFeedViewModel()
    @State private var expandedId: String?
    @State private var fraudId: String?
    @State private var appState = AppState.shared
    var body: some View {
        ZStack {
            AmbientBackground(isDark: appState.isDarkMode).ignoresSafeArea()
            VStack(spacing: 0) {
                FeedFilterBar(vm: vm)
                if vm.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.stCyan))
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(vm.filtered) { post in
                                PostCard(post: post, isExpanded: expandedId == post.id, showFraud: fraudId == post.id) {
                                    withAnimation(.stSpring) {
                                        if expandedId == post.id {
                                            fraudId = fraudId == post.id ? nil : post.id
                                        } else { expandedId = post.id; fraudId = nil }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 110)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Truth Feed")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
    }
}
