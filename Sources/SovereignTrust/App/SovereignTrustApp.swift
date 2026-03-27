import SwiftUI

@main
struct SovereignTrustApp: App {
    @State private var isReady = false
    @State private var showSplash = true
    @State private var bootError: String?

    init() {
        setupGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView(isReady: isReady) {
                        withAnimation(.easeInOut(duration: 0.4)) { showSplash = false }
                    }
                } else if let e = bootError {
                    BootErrorView(message: e)
                } else {
                    ContentView()
                        .preferredColorScheme(.dark)
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                }
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

// MARK: - Cinematic Splash Screen
struct SplashView: View {
    let isReady: Bool
    let onFinish: () -> Void

    @State private var phase = 0        // 0=rings, 1=logo, 2=text, 3=done
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.5
    @State private var ring2Opacity: Double = 0
    @State private var iconScale: CGFloat = 0.1
    @State private var iconOpacity: Double = 0
    @State private var iconGlow = false
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var progressOpacity: Double = 0
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    var body: some View {
        ZStack {
            AmbientBackground().ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [Color.stCyan.opacity(0.0), Color.stCyan.opacity(0.6), Color.stCyan.opacity(0.0)],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                        .rotationEffect(.degrees(iconGlow ? 360 : 0))
                        .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: iconGlow)

                    // Inner ring
                    Circle()
                        .stroke(Color.stCyan.opacity(0.15), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ring2Scale)
                        .opacity(ring2Opacity)

                    // Shield icon
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.stCyan, Color(hex:"7C3AED")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                        .shadow(color: Color.stCyan.opacity(iconGlow ? 0.6 : 0.2), radius: iconGlow ? 24 : 8)
                }

                // Title
                Text("Sovereign Trust")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)

                // Subtitle
                Text("Digital Identity Wallet")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.stCyan.opacity(0.7))
                    .opacity(subtitleOpacity)

                Spacer()

                // Loading indicator
                if !isReady {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.stCyan))
                        .opacity(progressOpacity)
                }

                Spacer().frame(height: 60)
            }
        }
        .scaleEffect(exitScale)
        .opacity(exitOpacity)
        .onAppear { runAnimation() }
        .onChange(of: isReady) { _, ready in
            if ready {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeIn(duration: 0.35)) {
                        exitScale = 1.08
                        exitOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onFinish() }
                }
            }
        }
    }

    private func runAnimation() {
        // Phase 0: Rings expand
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
            ringScale = 1.0; ringOpacity = 1.0
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.15)) {
            ring2Scale = 1.0; ring2Opacity = 1.0
        }
        // Phase 1: Icon appears
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
            iconScale = 1.0; iconOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            iconGlow = true
        }
        // Phase 2: Text slides in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
            titleOffset = 0; titleOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            subtitleOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.3).delay(1.0)) {
            progressOpacity = 1.0
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
