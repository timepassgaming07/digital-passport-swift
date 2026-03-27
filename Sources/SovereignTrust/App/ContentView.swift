import SwiftUI

struct ContentView: View {
    @State private var tab = 0
    @State private var appState = AppState.shared
    private let identity = Identity.mock

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                TabView(selection: $tab) {
                    HomeView()
                        .tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
                    ScanView()
                        .tabItem { Label("Scan", systemImage: "qrcode.viewfinder") }.tag(1)
                    PassportView(identity: identity)
                        .tabItem { Label("Passport", systemImage: "person.crop.rectangle.fill") }.tag(2)
                    VerifyView()
                        .tabItem { Label("Verify", systemImage: "checkmark.seal.fill") }.tag(3)
                    TruthFeedView()
                        .tabItem { Label("Feed", systemImage: "newspaper.fill") }.tag(4)
                }
                .tint(Color(hex: "22D3EE"))
                .toolbarColorScheme(.dark, for: .tabBar)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: NavRoute.self) { route in
                    switch route {
                    case .settings:    SettingsView(identity: identity)
                    case .trustEngine: TrustEngineView()
                    case .passport:    PassportView(identity: identity)
                    case .glassDemo:   GlassDemoView()
                    }
                }
            }
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
    }
}

enum NavRoute: Hashable {
    case settings, trustEngine, passport, glassDemo
}
