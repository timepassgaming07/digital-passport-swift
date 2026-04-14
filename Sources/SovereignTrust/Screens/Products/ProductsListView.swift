import SwiftUI
struct ProductsListView: View {
    let products = MockData.products
    @State private var selected: Product?
    @State private var walletVM = ProductAuthViewModel()
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:16) {
                    AppHeader(title:"Products",subtitle:"Authenticity verification")

                    // Quick action buttons
                    VStack(spacing: 10) {
                        HStack(spacing: 12) {
                            NavigationLink(destination: ProductAuthView()) {
                                HStack(spacing: 6) {
                                    Image(systemName: "qrcode.viewfinder").font(.caption.weight(.semibold))
                                    Text("Verify Product").font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(Color.stCyan)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                            }
                            .buttonStyle(.glass)

                            NavigationLink(destination: ProductWalletView()) {
                                HStack(spacing: 6) {
                                    Image(systemName: "wallet.bifold").font(.caption.weight(.semibold))
                                    Text("My Wallet").font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(Color(hex: "00FF88"))
                                .padding(.horizontal, 14).padding(.vertical, 10)
                            }
                            .buttonStyle(.glass)
                            Spacer()
                        }

                        HStack(spacing: 12) {
                            NavigationLink(destination: ManufacturerVerifyView()) {
                                HStack(spacing: 6) {
                                    Image(systemName: "building.2.fill").font(.caption.weight(.semibold))
                                    Text("Manufacturer Verify").font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(Color.stGold)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                            }
                            .buttonStyle(.glass)

                            NavigationLink(destination: DocumentRequestWorkflowView()) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.text.viewfinder").font(.caption.weight(.semibold))
                                    Text("File Request QR").font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(Color.stBlue)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                            }
                            .buttonStyle(.glass)
                            Spacer()
                        }
                    }

                    // Owned products section
                    if !walletVM.ownedProducts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Owned Products").font(.stHeadline).foregroundStyle(Color.stPrimary)
                                Spacer()
                                Text("\(walletVM.ownedProducts.count)").font(.stCaption).foregroundStyle(Color.stSecondary)
                            }
                            ForEach(walletVM.ownedProducts, id: \.0.id) { reg, ownership in
                                ProductCard(product: reg.product).glassPress { selected = reg.product }
                            }
                        }
                    }

                    // All products
                    VStack(alignment: .leading, spacing: 10) {
                        Text("All Products").font(.stHeadline).foregroundStyle(Color.stPrimary)
                        if products.isEmpty {
                            EmptyState(icon:"shippingbox",title:"No products",message:"Scan a product QR code to verify authenticity")
                        } else {
                            ForEach(products) { p in
                                ProductCard(product:p).glassPress { selected = p }
                            }
                        }
                    }

                    Spacer(minLength:90)
                }
                .padding(.horizontal,20).padding(.top,8)
            }
        }
        .navigationTitle("Products")
        .toolbarColorScheme(.dark,for:.navigationBar)
        .navigationDestination(item:$selected) { p in ProductDetailView(product:p) }
        .task { walletVM.loadWallet() }
    }
}
