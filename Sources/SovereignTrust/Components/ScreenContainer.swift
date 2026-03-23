import SwiftUI
struct ScreenContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @State private var appState = AppState.shared
    var body: some View {
        ZStack {
            AmbientBackground(isDark: appState.isDarkMode).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                content()
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 110)
            }
            .scrollContentBackground(.hidden)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
