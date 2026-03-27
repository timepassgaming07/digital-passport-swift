import SwiftUI

/// Demo screen showcasing the complete Liquid Glass system.
/// Accessible from Settings or as a standalone preview.
struct GlassDemoView: View {
    @State private var searchText = ""
    @State private var inputText = ""
    @State private var showPanel = false
    @State private var floatY: CGFloat = 0
    @State private var appState = AppState.shared
    private var dark: Bool { appState.isDarkMode }

    var body: some View {
        ZStack {
            AmbientBackground(isDark: dark).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    searchBar
                    heroCard
                    glassCardsSection
                    buttonsSection
                    inputSection
                    chipsSection
                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 110)
            }
            .scrollContentBackground(.hidden)

            // Floating Panel Overlay
            if showPanel {
                Color.black.opacity(0.3).ignoresSafeArea()
                    .onTapGesture { withAnimation(.stSpring) { showPanel = false } }
                floatingPanel
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Glass Demo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { withAnimation(.stFloat) { floatY = 3 } }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Liquid Glass").font(.largeTitle.bold())
                    .foregroundStyle(dark ? .white : Color(hex: "111827"))
                Text("Native Material System").font(.subheadline)
                    .foregroundStyle(dark ? Color.white.opacity(0.65) : Color(hex: "374151"))
            }
            Spacer()
            Image(systemName: "sparkles")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.stCyan)
                .frame(width: 40, height: 40)
                .glass(cornerRadius: .infinity, glow: .stCyan, glowIntensity: 0.25)
        }
    }

    // MARK: - Search
    private var searchBar: some View {
        GlassSearchBar(text: $searchText, placeholder: "Search glass components…")
    }

    // MARK: - Hero Card
    private var heroCard: some View {
        GlassCard(cornerRadius: 28, innerPadding: 0, style: .liquid) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(colors: [.stCyan, .stPurple],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: Color.stCyan.opacity(0.4), radius: 10)
                        Image(systemName: "apple.logo")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iOS 26 Native Glass").font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Built on Apple .glassEffect()").font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.65))
                        Text(".glassEffect(.regular)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.40))
                    }
                    Spacer()
                }
                .padding(18)

                GlassDivider()

                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.stCyan).font(.caption)
                    Text("Native Performance")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.65))
                    Spacer()
                    TrustBadge(state: .verified, size: .small)
                }
                .padding(.horizontal, 18).padding(.vertical, 11)
            }
        }
        .offset(y: floatY)
    }

    // MARK: - Cards Grid
    private var glassCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassSectionHeader(title: "Glass Card Tiers", icon: "rectangle.3.group")

            HStack(spacing: 12) {
                GlassCard(cornerRadius: 20, innerPadding: 14, style: .liquid) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("💧").font(.title2)
                        Text("Liquid").font(.headline.weight(.semibold)).foregroundStyle(.white)
                        Text(".ultraThin").font(.caption).foregroundStyle(.white.opacity(0.5))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }

                GlassCard(cornerRadius: 20, innerPadding: 14, style: .frost) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("❄️").font(.title2)
                        Text("Frost").font(.headline.weight(.semibold)).foregroundStyle(.white)
                        Text(".thinMaterial").font(.caption).foregroundStyle(.white.opacity(0.5))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }

                GlassCard(cornerRadius: 20, innerPadding: 14, style: .thick) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🧊").font(.title2)
                        Text("Thick").font(.headline.weight(.semibold)).foregroundStyle(.white)
                        Text(".regularMaterial").font(.caption).foregroundStyle(.white.opacity(0.5))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Buttons
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassSectionHeader(title: "Glass Buttons", icon: "hand.tap")

            GlassButton(label: "Primary Action", icon: "checkmark.seal.fill", variant: .primary, fullWidth: true) {}
            GlassButton(label: "Secondary", icon: "arrow.right", variant: .secondary, fullWidth: true) {}
            GlassButton(label: "Danger", icon: "exclamationmark.triangle", variant: .danger, fullWidth: true) {}

            HStack(spacing: 12) {
                GlassButton(label: "Compact", icon: "star.fill") {}
                GlassButton(label: "Ghost", icon: "eye", variant: .ghost) {}
            }

            GlassButton(label: "Show Floating Panel", icon: "rectangle.on.rectangle", variant: .primary, fullWidth: true) {
                withAnimation(.stSpring) { showPanel = true }
            }
        }
    }

    // MARK: - Inputs
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassSectionHeader(title: "Glass Inputs", icon: "text.cursor")
            GlassTextField(placeholder: "Enter something…", text: $inputText, icon: "pencil")
        }
    }

    // MARK: - Chips
    private var chipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassSectionHeader(title: "Glass Chips", icon: "tag")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    GlassChip(label: "Verified", icon: "checkmark.seal", color: .stGreen, isActive: true)
                    GlassChip(label: "Trusted", icon: "shield", color: .stBlue, isActive: true)
                    GlassChip(label: "Pending", icon: "clock", color: .stGold)
                    GlassChip(label: "Suspicious", icon: "exclamationmark.triangle", color: .stOrange)
                    GlassChip(label: "Revoked", icon: "xmark.seal", color: .stRed)
                }
            }
        }
    }

    // MARK: - Floating Panel
    private var floatingPanel: some View {
        GlassFloatingPanel(glowColor: .stCyan, glowIntensity: 0.15) {
            VStack(spacing: 16) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.stCyan)
                    .shadow(color: Color.stCyan.opacity(0.5), radius: 12)
                Text("Floating Glass Panel").font(.title3.weight(.semibold)).foregroundStyle(.white)
                Text("Native iOS 26 .glassEffect() — true liquid glass.")
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                GlassDivider()
                GlassButton(label: "Dismiss", icon: "xmark", variant: .secondary, fullWidth: true) {
                    withAnimation(.stSpring) { showPanel = false }
                }
            }
        }
        .padding(.horizontal, 32)
    }
}
