import SwiftUI
import MapKit

struct ProductDetailView: View {
    let product: Product
    @State private var scanHistory: [ProductScanEvent] = []
    @State private var registeredProduct: RegisteredProduct?

    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:20) {
                    // Product info card
                    GlassCard(cornerRadius:28,glowColor:product.trustState.glowColor,glowOpacity:0.08) {
                        VStack(alignment:.leading,spacing:12) {
                            HStack {
                                VStack(alignment:.leading,spacing:4) {
                                    Text(product.brand).font(.stCaption).foregroundStyle(Color.stSecondary)
                                    Text(product.name).font(.stTitle2).foregroundStyle(Color.stPrimary)
                                    Text(product.category).font(.stBodySm).foregroundStyle(Color.stTertiary)
                                }
                                Spacer()
                                TrustBadge(state:product.trustState)
                            }
                            Divider().background(Color.white.opacity(0.1))
                            HStack { Text("SN").font(.stCaption).foregroundStyle(Color.stTertiary); Spacer()
                                Text(product.serialNumber).font(.stMono).foregroundStyle(Color.stSecondary) }
                            HStack { Text("Manufactured").font(.stCaption).foregroundStyle(Color.stTertiary); Spacer()
                                Text(product.manufacturedAt.formatted(style:.medium)).font(.stCaption).foregroundStyle(Color.stSecondary) }
                        }
                    }

                    // Manufacturer verification info
                    if let reg = registeredProduct {
                        manufacturerVerificationCard(reg)
                    }

                    // Scan history map
                    if !scanLocations.isEmpty {
                        scanMapCard
                    }

                    // Scan history timeline
                    if !scanHistory.isEmpty {
                        scanHistorySection
                    }

                    CustodyChainView(chain:product.custodyChain)
                    Spacer(minLength:90)
                }
                .padding(.horizontal,20).padding(.top,8)
            }
        }
        .navigationTitle(product.name)
        .toolbarColorScheme(.dark,for:.navigationBar)
        .task {
            scanHistory = await ProductAuthService.shared.scanHistory(for: product.id)
            registeredProduct = await ProductAuthService.shared.registeredProduct(product.id)
        }
    }

    // MARK: – Manufacturer Verification Card

    private func manufacturerVerificationCard(_ reg: RegisteredProduct) -> some View {
        GlassCard(cornerRadius: 22, glowColor: Color(hex: "00FF88"), glowOpacity: 0.08, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "building.2.fill").foregroundStyle(Color(hex: "00FF88")).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manufacturer Verified").font(.stHeadline).foregroundStyle(Color.stPrimary)
                        Text("First scan by manufacturer").font(.stCaption).foregroundStyle(Color.stSecondary)
                    }
                    Spacer()
                    TrustBadge(state: .verified, size: .small)
                }

                Divider().background(Color.white.opacity(0.1))

                detailRow("Verified At", reg.manufacturerVerifiedAt.formatted(style: .medium))
                detailRow("Signature", Formatters.shortHash(reg.manufacturerSignature))
                if let assessment = reg.latestAssessment {
                    detailRow("ML Authenticity Score", "\(assessment.score)/100 (\(assessment.riskLevel.label))")
                    detailRow("Model Confidence", "\(assessment.confidence)%")
                }
                if let did = reg.manufacturerDid {
                    detailRow("Manufacturer DID", Formatters.shortDID(did))
                }
                if let loc = reg.manufacturerLocation {
                    detailRow("Verification Location", loc.formattedAddress)
                    detailRow("GPS Coordinates", "\(String(format: "%.6f", loc.latitude)), \(String(format: "%.6f", loc.longitude))")
                } else {
                    detailRow("Verification Location", "Not captured (pre-registered)")
                }
            }
        }
    }

    // MARK: – Scan Map

    private var scanLocations: [(ProductScanEvent, ProductLocation)] {
        scanHistory.compactMap { event in
            guard let loc = event.location else { return nil }
            return (event, loc)
        }
    }

    private var scanMapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scan Locations").font(.stHeadline).foregroundStyle(Color.stPrimary)
            Text("Real GPS locations of each scan").font(.stCaption).foregroundStyle(Color.stSecondary)

            GlassCard(cornerRadius: 20, innerPadding: 0) {
                let coords = scanLocations.map {
                    CLLocationCoordinate2D(latitude: $0.1.latitude, longitude: $0.1.longitude)
                }
                let center = coords.isEmpty
                    ? CLLocationCoordinate2D(latitude: 20.0, longitude: 78.0)
                    : CLLocationCoordinate2D(
                        latitude: coords.map(\.latitude).reduce(0, +) / Double(coords.count),
                        longitude: coords.map(\.longitude).reduce(0, +) / Double(coords.count)
                      )
                let span = coords.count == 1
                    ? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    : MKCoordinateSpan(latitudeDelta: max(0.05, (coords.map(\.latitude).max() ?? 0) - (coords.map(\.latitude).min() ?? 0) + 0.02),
                                       longitudeDelta: max(0.05, (coords.map(\.longitude).max() ?? 0) - (coords.map(\.longitude).min() ?? 0) + 0.02))

                Map(initialPosition: .region(MKCoordinateRegion(center: center, span: span))) {
                    ForEach(scanLocations, id: \.0.id) { event, loc in
                        Marker(
                            event.actor == .manufacturer ? "Manufacturer" : "Consumer Scan",
                            coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                        )
                        .tint(event.actor == .manufacturer ? Color(hex: "00FF88") : Color(hex: "22D3EE"))
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "00FF88")).frame(width: 8, height: 8)
                    Text("Manufacturer").font(.stCaption).foregroundStyle(Color.stSecondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "22D3EE")).frame(width: 8, height: 8)
                    Text("Consumer").font(.stCaption).foregroundStyle(Color.stSecondary)
                }
            }
        }
    }

    // MARK: – Scan History Timeline

    private var scanHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scan History").font(.stHeadline).foregroundStyle(Color.stPrimary)
            Text("\(scanHistory.count) scan\(scanHistory.count == 1 ? "" : "s") recorded")
                .font(.stCaption).foregroundStyle(Color.stSecondary)

            GlassCard(cornerRadius: 22, innerPadding: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(scanHistory.enumerated()), id: \.element.id) { idx, event in
                        HStack(alignment: .top, spacing: 14) {
                            VStack(spacing: 0) {
                                ZStack {
                                    Circle()
                                        .fill((event.actor == .manufacturer ? Color(hex: "00FF88") : Color(hex: "22D3EE")).opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: event.actor == .manufacturer ? "building.2.fill" : "person.fill")
                                        .font(.caption)
                                        .foregroundStyle(event.actor == .manufacturer ? Color(hex: "00FF88") : Color(hex: "22D3EE"))
                                }
                                if idx < scanHistory.count - 1 {
                                    Rectangle()
                                        .fill(Color.stCyan.opacity(0.2))
                                        .frame(width: 2, height: 28)
                                }
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(event.actor == .manufacturer ? "Manufacturer Scan" : "Consumer Scan")
                                        .font(.stHeadline).foregroundStyle(Color.stPrimary)
                                    Spacer()
                                    Text(event.actor.rawValue.uppercased())
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(event.actor == .manufacturer ? Color(hex: "00FF88") : Color(hex: "22D3EE"))
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background((event.actor == .manufacturer ? Color(hex: "00FF88") : Color(hex: "22D3EE")).opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                Text(event.scannedAt.formatted(style: .medium))
                                    .font(.stCaption).foregroundStyle(Color.stTertiary)
                                if let loc = event.location {
                                    Label(loc.formattedAddress, systemImage: "mappin.circle")
                                        .font(.stCaption).foregroundStyle(Color.stSecondary)
                                    Text("\(String(format: "%.4f", loc.latitude)), \(String(format: "%.4f", loc.longitude))")
                                        .font(.stMonoSm).foregroundStyle(Color.stTertiary)
                                } else {
                                    Label("Location not captured", systemImage: "location.slash")
                                        .font(.stCaption).foregroundStyle(Color.stTertiary)
                                }
                                Text("Result: \(event.result)")
                                    .font(.stCaption).foregroundStyle(Color.stTertiary)
                                if let score = event.authenticityScore {
                                    let risk = event.riskLevel?.label.uppercased() ?? "UNKNOWN"
                                    Text("ML Score: \(score)/100 • \(risk)")
                                        .font(.stCaption).foregroundStyle(Color.stCyan)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }

    // MARK: – Helpers

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.stCaption).foregroundStyle(Color.stTertiary)
            Text(value).font(.stMono).foregroundStyle(Color.stSecondary).lineLimit(2)
        }
    }
}
