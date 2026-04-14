import SwiftUI
import MapKit

// MARK: – Manufacturer Verify View
// Manufacturer scans a product QR to register it in the registry.
// Captures real GPS location as "first scan" proof.

struct ManufacturerVerifyView: View {
    @State private var appState = AppState.shared
    @State private var showScanner = false
    @State private var hasAutoOpened = false

    // Verification state
    @State private var isVerifying = false
    @State private var registeredProduct: RegisteredProduct?
    @State private var alreadyRegistered = false
    @State private var errorMessage: String?

    // Location state
    @State private var scanLocation: ProductLocation?
    @State private var isResolvingLocation = false
    @State private var locationError: String?

    // Registered products list
    @State private var allRegistered: [RegisteredProduct] = []

    private var dark: Bool { appState.isDarkMode }

    var body: some View {
        ZStack {
            AmbientBackground(isDark: dark).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    locationStatusCard
                    scanButton
                    if isVerifying { verifyingSpinner }
                    if let reg = registeredProduct { successCard(reg) }
                    if alreadyRegistered { alreadyRegisteredCard }
                    if let err = errorMessage { errorCard(err) }
                    if !allRegistered.isEmpty { registeredProductsList }
                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Manufacturer Verify")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.stSpring, value: isVerifying)
        .animation(.stSpring, value: registeredProduct != nil)
        .animation(.stSpring, value: alreadyRegistered)
        .sheet(isPresented: $showScanner) {
            ProductScannerSheet { payload in
                showScanner = false
                registerFromPayload(payload)
            }
        }
        .task {
            // Request location permission on appear
            LocationService.shared.requestPermission()
            await resolveLocation()
            await loadRegistered()
            // Auto-open scanner once location is ready
            if !hasAutoOpened {
                hasAutoOpened = true
                showScanner = true
            }
        }
    }

    // MARK: – Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Manufacturer Verification")
                .font(.largeTitle.bold()).foregroundStyle(Color.primary(dark: dark))
            Text("Scan product QR to register in the authenticity registry. Your GPS location is recorded as the first verification point.")
                .font(.subheadline).foregroundStyle(Color.secondary(dark: dark))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Location Status

    private var locationStatusCard: some View {
        GlassCard(cornerRadius: 18, glowColor: scanLocation != nil ? Color(hex: "00FF88") : Color.stOrange, glowOpacity: 0.08, innerPadding: 14) {
            HStack(spacing: 12) {
                if isResolvingLocation {
                    ProgressView().tint(Color.stCyan)
                } else {
                    Image(systemName: scanLocation != nil ? "location.fill" : "location.slash")
                        .font(.title3)
                        .foregroundStyle(scanLocation != nil ? Color(hex: "00FF88") : Color.stOrange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(scanLocation != nil ? "Location Captured" : "Location Required")
                        .font(.stHeadline).foregroundStyle(Color.stPrimary)
                    if let loc = scanLocation {
                        Text(loc.formattedAddress).font(.stCaption).foregroundStyle(Color.stSecondary)
                        Text("\(String(format: "%.4f", loc.latitude)), \(String(format: "%.4f", loc.longitude))")
                            .font(.stMonoSm).foregroundStyle(Color.stTertiary)
                    } else if let err = locationError {
                        Text(err).font(.stCaption).foregroundStyle(Color.stOrange)
                    } else {
                        Text("Resolving GPS coordinates…").font(.stCaption).foregroundStyle(Color.stSecondary)
                    }
                }
                Spacer()
                if scanLocation == nil && !isResolvingLocation {
                    Button {
                        Task { await resolveLocation() }
                    } label: {
                        Text("Retry").font(.stCaption).foregroundStyle(Color.stCyan)
                    }
                }
            }
        }
    }

    // MARK: – Scan Button

    private var scanButton: some View {
        GlassButton(label: "Scan Product QR", icon: "qrcode.viewfinder", fullWidth: true) {
            showScanner = true
        }
    }

    // MARK: – Verifying Spinner

    private var verifyingSpinner: some View {
        GlassCard(cornerRadius: 22, innerPadding: 20) {
            HStack(spacing: 14) {
                ProgressView().tint(Color.stCyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Registering Product…").font(.stHeadline).foregroundStyle(Color.stPrimary)
                    Text("Capturing location & signing verification").font(.stCaption).foregroundStyle(Color.stSecondary)
                }
                Spacer()
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: – Success Card

    private func successCard(_ reg: RegisteredProduct) -> some View {
        GlassCard(cornerRadius: 24, glowColor: Color(hex: "00FF88"), glowOpacity: 0.15, innerPadding: 0) {
            VStack(spacing: 0) {
                Rectangle().fill(Color(hex: "00FF88")).frame(height: 3)
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color(hex: "00FF88").opacity(0.12)).frame(width: 64, height: 64)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 34)).foregroundStyle(Color(hex: "00FF88"))
                    }
                    .shadow(color: Color(hex: "00FF88").opacity(0.5), radius: 16)

                    Text("PRODUCT REGISTERED").font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "00FF88")).tracking(1.5)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(reg.product.brand).font(.stCaption).foregroundStyle(Color.stSecondary)
                        Text(reg.product.name).font(.stTitle2).foregroundStyle(Color.stPrimary)

                        Divider().background(Color.white.opacity(0.1))

                        detailRow("Serial", reg.product.serialNumber)
                        detailRow("Signature", Formatters.shortHash(reg.manufacturerSignature))
                        detailRow("QR Hash", Formatters.shortHash(reg.qrHash))
                        if let assessment = reg.latestAssessment {
                            detailRow("ML Authenticity Score", "\(assessment.score)/100 (\(assessment.riskLevel.label))")
                            detailRow("Model Confidence", "\(assessment.confidence)%")
                        }
                        detailRow("Verified At", reg.manufacturerVerifiedAt.formatted(style: .medium))
                        if let did = reg.manufacturerDid {
                            detailRow("Manufacturer", Formatters.shortDID(did))
                        }
                        if let loc = reg.manufacturerLocation {
                            detailRow("First Scan Location", loc.formattedAddress)
                            detailRow("GPS", "\(String(format: "%.6f", loc.latitude)), \(String(format: "%.6f", loc.longitude))")
                        }
                    }

                    // Map showing manufacturer scan location
                    if let loc = reg.manufacturerLocation {
                        mapCard(location: loc, label: "Manufacturer Verification Point")
                    }

                    Text("Consumers scanning this product will see it as verified")
                        .font(.stCaption).foregroundStyle(Color.stTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: – Already Registered

    private var alreadyRegisteredCard: some View {
        GlassCard(cornerRadius: 24, glowColor: Color.stBlue, glowOpacity: 0.10, innerPadding: 16) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.stBlue.opacity(0.12)).frame(width: 48, height: 48)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2).foregroundStyle(Color.stBlue)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ALREADY REGISTERED").font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.stBlue).tracking(1)
                        Text("This product is already in the registry")
                            .font(.stBodySm).foregroundStyle(Color.stSecondary)
                    }
                    Spacer()
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: – Error Card

    private func errorCard(_ message: String) -> some View {
        GlassCard(cornerRadius: 22, glowColor: Color.stRed, glowOpacity: 0.10, innerPadding: 16) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.stRed)
                Text(message).font(.stBody).foregroundStyle(Color.stSecondary)
                Spacer()
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: – Registered Products List

    private var registeredProductsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Registered Products").font(.stHeadline).foregroundStyle(Color.stPrimary)
            Text("\(allRegistered.count) products in registry")
                .font(.stCaption).foregroundStyle(Color.stSecondary)

            ForEach(allRegistered) { reg in
                GlassCard(cornerRadius: 18, innerPadding: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color(hex: "00FF88").opacity(0.10)).frame(width: 36, height: 36)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption).foregroundStyle(Color(hex: "00FF88"))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reg.product.name).font(.stHeadline).foregroundStyle(Color.stPrimary)
                            Text(reg.product.brand).font(.stCaption).foregroundStyle(Color.stSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if let loc = reg.manufacturerLocation {
                                Text(loc.city).font(.stCaption).foregroundStyle(Color.stTertiary)
                            } else {
                                Text("No GPS").font(.stCaption).foregroundStyle(Color.stTertiary)
                            }
                            if let score = reg.latestAssessment?.score {
                                Text("ML \(score)").font(.stMonoSm).foregroundStyle(Color.stCyan)
                            }
                            Text(reg.manufacturerVerifiedAt.formatted(style: .short))
                                .font(.stMonoSm).foregroundStyle(Color.stTertiary)
                        }
                    }
                }
            }
        }
    }

    // MARK: – Map Card

    private func mapCard(location: ProductLocation, label: String) -> some View {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)

        return GlassCard(cornerRadius: 16, innerPadding: 0) {
            VStack(spacing: 0) {
                Map(initialPosition: .region(region)) {
                    Marker(label, coordinate: coordinate)
                        .tint(Color(hex: "00FF88"))
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: – Helpers

    private func resolveLocation() async {
        isResolvingLocation = true
        locationError = nil
        let loc = await LocationService.shared.resolveCurrentLocation()
        scanLocation = loc
        isResolvingLocation = false
        if loc == nil {
            locationError = "Enable Location Services in Settings to capture verification location"
        }
    }

    private func loadRegistered() async {
        allRegistered = await ProductAuthService.shared.allRegisteredProducts()
    }

    private func registerFromPayload(_ payload: String) {
        isVerifying = true
        registeredProduct = nil
        alreadyRegistered = false
        errorMessage = nil

        let parsed = QRParserService.parse(payload)
        let productId = parsed.payload?.id ?? ""
        let mfrDid = parsed.payload?.did ?? "unknown"

        guard !productId.isEmpty else {
            errorMessage = "Invalid QR code — no product ID found"
            isVerifying = false
            return
        }

        Task {
            // Ensure location is fresh
            if scanLocation == nil {
                await resolveLocation()
            }

            // Check if already registered
            let exists = await ProductAuthService.shared.isRegistered(productId)
            if exists {
                self.alreadyRegistered = true
                self.isVerifying = false
                return
            }

            // Build product from QR payload — DID comes from the QR itself
            let product = Product(
                id: productId,
                name: parsed.payload?.title ?? "Unknown Product",
                brand: parsed.payload?.brand ?? "Unknown",
                serialNumber: parsed.payload?.serial ?? "N/A",
                manufacturerDid: mfrDid,
                status: .authentic,
                trustState: .verified,
                custodyChain: [],
                manufacturedAt: Date(),
                description: "",
                category: parsed.payload?.t ?? "General"
            )

            let reg = await ProductAuthService.shared.registerProduct(
                product,
                location: scanLocation,
                manufacturerDid: mfrDid,
                rawPayload: payload
            )
            self.registeredProduct = reg
            self.isVerifying = false
            await loadRegistered()
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.stCaption).foregroundStyle(Color.stTertiary)
            Text(value).font(.stMono).foregroundStyle(Color.stSecondary).lineLimit(2)
        }
    }
}
