import SwiftUI

@main
struct SovereignTrustApp: App {
    @State private var isReady = false
    @State private var bootError: String?

    init() {
        setupGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isReady { ContentView().preferredColorScheme(.dark) }
                else if let e = bootError { BootErrorView(message: e) }
                else { BootView() }
            }
            .task { await boot() }
        }
    }

    private func boot() async {
        do {
            try await DatabaseManager.shared.setup()
            await MainActor.run { isReady = true }
        } catch {
            await MainActor.run { bootError = error.localizedDescription }
        }
    }
}

struct BootView: View {
    @State private var glow = false
    var body: some View {
        ZStack {
            AmbientBackground().ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill").font(.system(size: 64))
                    .foregroundStyle(Color.stCyan)
                    .scaleEffect(glow ? 1.06 : 0.96)
                    .shadow(color: Color.stCyan.opacity(0.5), radius: glow ? 24 : 8)
                    .animation(.stPulse, value: glow)
                Text("Sovereign Trust").font(.largeTitle.bold()).foregroundStyle(.white)
                Text("Initialising…").font(.subheadline).foregroundStyle(.white.opacity(0.6))
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.stCyan))
            }
        }
        .onAppear { glow = true }
    }
}

struct BootErrorView: View {
    let message: String
    var body: some View {
        ZStack {
            AmbientBackground().ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52)).foregroundStyle(Color.stRed)
                Text("Initialisation Failed").font(.title2.bold()).foregroundStyle(.white)
                Text(message).font(.subheadline).foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }.padding(32)
        }
    }
}
