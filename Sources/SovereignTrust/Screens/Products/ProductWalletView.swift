import SwiftUI

// MARK: – Product Wallet View
// Shows all products the user has claimed ownership of.

struct ProductWalletView: View {
    @State private var vm = ProductAuthViewModel()
    @State private var appState = AppState.shared
    @State private var selectedProduct: RegisteredProduct?
    private var dark: Bool { appState.isDarkMode }

    var body: some View {
        ZStack {
            AmbientBackground(isDark: dark).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Products").font(.largeTitle.bold()).foregroundStyle(Color.primary(dark: dark))
                        Text("Products you own — verified first ownership")
                            .font(.subheadline).foregroundStyle(Color.secondary(dark: dark))
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    if vm.isLoadingWallet {
                        LoadingState(message: "Loading wallet…")
                    } else if vm.ownedProducts.isEmpty {
                        emptyState
                    } else {
                        ForEach(vm.ownedProducts, id: \.0.id) { reg, ownership in
                            ownedProductCard(reg: reg, ownership: ownership)
                                .glassPress { selectedProduct = reg }
                        }
                    }

                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { vm.loadWallet() }
        .navigationDestination(item: $selectedProduct) { reg in
            ProductDetailView(product: reg.product)
        }
    }

    // MARK: – Empty State

    private var emptyState: some View {
        GlassCard(cornerRadius: 24, innerPadding: 32) {
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.stCyan.opacity(0.08)).frame(width: 80, height: 80)
                    Image(systemName: "wallet.bifold").font(.system(size: 36)).foregroundStyle(Color.stCyan)
                }
                Text("No Products Yet").font(.stTitle3).foregroundStyle(Color.stPrimary)
                Text("Scan a product QR code and enter the OTP to claim ownership. Your verified products will appear here.")
                    .font(.stBodySm).foregroundStyle(Color.stSecondary)
                    .multilineTextAlignment(.center)
                NavigationLink(destination: ProductAuthView()) {
                    HStack(spacing: 8) {
                        Image(systemName: "qrcode.viewfinder").font(.body.weight(.semibold))
                        Text("Scan Product").font(.body.weight(.semibold))
                    }
                    .foregroundStyle(Color.stCyan)
                    .padding(.horizontal, 22).padding(.vertical, 13)
                }
                .buttonStyle(.glass)
            }
        }
    }

    // MARK: – Owned Product Card

    private func ownedProductCard(reg: RegisteredProduct, ownership: ProductOwnership) -> some View {
        GlassCard(cornerRadius: 24, glowColor: Color(hex: "00FF88"), glowOpacity: 0.08, innerPadding: 0) {
            VStack(spacing: 0) {
                // Green accent
                Rectangle().fill(Color(hex: "00FF88")).frame(height: 3)

                HStack(spacing: 0) {
                    // Left icon bar
                    VStack {
                        ZStack {
                            Circle().fill(Color(hex: "00FF88").opacity(0.12)).frame(width: 40, height: 40)
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color(hex: "00FF88")).font(.body)
                        }
                    }
                    .padding(.horizontal, 14)

                    // Product info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reg.product.brand).font(.stCaption).foregroundStyle(Color.stSecondary)
                        Text(reg.product.name).font(.stHeadline).foregroundStyle(Color.stPrimary)
                        HStack(spacing: 8) {
                            Label(reg.product.category, systemImage: "shippingbox")
                                .font(.stCaption).foregroundStyle(Color.stTertiary)
                            HStack(spacing: 4) {
                                Circle().fill(Color(hex: "00FF88")).frame(width: 5, height: 5)
                                Text("OWNED").font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "00FF88")).tracking(0.8)
                            }
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .glassEffect(Glass.clear.tint(Color(hex: "00FF88").opacity(0.15)), in: .capsule)
                        }
                        Text("SN: \(reg.product.serialNumber)").font(.stMonoSm).foregroundStyle(Color.stTertiary)
                        HStack(spacing: 4) {
                            Image(systemName: "calendar").font(.caption2)
                            Text("Claimed \(ownership.claimedAt.formatted(style: .medium))")
                                .font(.stCaption)
                        }
                        .foregroundStyle(Color.stTertiary)
                        if let loc = ownership.claimLocation {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle").font(.caption2)
                                Text(loc.formattedAddress).font(.stCaption)
                            }
                            .foregroundStyle(Color.stTertiary)
                        }
                    }
                    .padding(.vertical, 14)

                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.35)).padding(.trailing, 14)
                }
            }
        }
    }
}
