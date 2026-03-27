import SwiftUI
struct ProductsListView: View {
    let products = MockData.products
    @State private var selected: Product?
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:16) {
                    AppHeader(title:"Products",subtitle:"Authenticity verification")
                    if products.isEmpty {
                        EmptyState(icon:"shippingbox",title:"No products",message:"Scan a product QR code to verify authenticity")
                    } else {
                        ForEach(products) { p in
                            ProductCard(product:p).glassPress { selected = p }
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
    }
}
