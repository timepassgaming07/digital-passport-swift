import SwiftUI
import MapKit

// MARK: – Product Authentication View
// Full flow: scan → verify → OTP → claim ownership
// Uses real GPS location — no simulation.

struct ProductAuthView: View {
    @State private var vm = ProductAuthViewModel()
    @State private var appState = AppState.shared
    @State private var showScanner = false
    @State private var hasAutoOpened = false
    private var dark: Bool { appState.isDarkMode }

    var body: some View {
        ZStack {
            AmbientBackground(isDark: dark).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    locationStatusCard
                    scanSection
                    if vm.isVerifying { verifyingState }
                    if let status = vm.verificationStatus, !vm.isVerifying {
                        resultSection(status)
                    }
                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Product Auth")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.stSpring, value: vm.isVerifying)
        .animation(.stSpring, value: vm.verificationStatus != nil)
        .animation(.stSpring, value: vm.currentOTP != nil)
        .animation(.stSpring, value: vm.claimedOwnership != nil)
        .sheet(isPresented: $showScanner) {
            ProductScannerSheet { payload in
                showScanner = false
                vm.verifyProduct(rawPayload: payload)
            }
        }
        .task {
            LocationService.shared.requestPermission()
            await vm.resolveLocation()
            if !hasAutoOpened {
                hasAutoOpened = true
                showScanner = true
            }
        }
    }

    // MARK: – Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Product Authentication").font(.largeTitle.bold()).foregroundStyle(Color.primary(dark: dark))
            Text("Scan product QR to verify authenticity & claim ownership")
                .font(.subheadline).foregroundStyle(Color.secondary(dark: dark))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Location Status

    private var locationStatusCard: some View {
        GlassCard(cornerRadius: 18, glowColor: vm.scanLocation != nil ? Color(hex: "00FF88") : Color.stOrange, glowOpacity: 0.06, innerPadding: 12) {
            HStack(spacing: 10) {
                if vm.isResolvingLocation {
                    ProgressView().tint(Color.stCyan)
                } else {
                    Image(systemName: vm.scanLocation != nil ? "location.fill" : "location.slash")
                        .foregroundStyle(vm.scanLocation != nil ? Color(hex: "00FF88") : Color.stOrange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    if let loc = vm.scanLocation {
                        Text(loc.formattedAddress).font(.stCaption).foregroundStyle(Color.stSecondary)
                    } else if let err = vm.locationError {
                        Text(err).font(.stCaption).foregroundStyle(Color.stOrange)
                    } else {
                        Text("Resolving location…").font(.stCaption).foregroundStyle(Color.stSecondary)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: – Scan Section

    private var scanSection: some View {
        GlassButton(label: "Scan Product QR", icon: "qrcode.viewfinder", fullWidth: true) {
            showScanner = true
        }
    }

    // MARK: – Verifying Spinner

    private var verifyingState: some View {
        GlassCard(cornerRadius: 22, innerPadding: 20) {
            HStack(spacing: 14) {
                ProgressView().tint(Color.stCyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Verifying Product…").font(.stHeadline).foregroundStyle(Color.stPrimary)
                    Text("Checking manufacturer registry").font(.stCaption).foregroundStyle(Color.stSecondary)
                }
                Spacer()
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: – Result Section

    @ViewBuilder
    private func resultSection(_ status: ProductVerificationStatus) -> some View {
        switch status {
        case .authentic(let reg, let assessment):
            authenticResult(reg, assessment: assessment)
        case .counterfeit(let reason, let assessment):
            counterfeitResult(reason, assessment: assessment)
        case .unregistered(let assessment):
            unregisteredResult(assessment: assessment)
        case .alreadyOwned(let ownership, let assessment):
            alreadyOwnedResult(ownership, assessment: assessment)
        }
    }

    // MARK: – Authentic Product

    private func authenticResult(_ reg: RegisteredProduct, assessment: ProductAuthenticityAssessment) -> some View {
        VStack(spacing: 16) {
            // Verified banner
            GlassCard(cornerRadius: 24, glowColor: Color(hex: "00FF88"), glowOpacity: 0.12, innerPadding: 0) {
                VStack(spacing: 0) {
                    // Green accent stripe
                    Rectangle().fill(Color(hex: "00FF88")).frame(height: 3)

                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color(hex: "00FF88").opacity(0.12)).frame(width: 52, height: 52)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title2).foregroundStyle(Color(hex: "00FF88"))
                            }
                            .shadow(color: Color(hex: "00FF88").opacity(0.4), radius: 10)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("AUTHENTIC PRODUCT").font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "00FF88")).tracking(1.2)
                                Text("Manufacturer verified ✓").font(.stBodySm).foregroundStyle(Color.stSecondary)
                            }
                            Spacer()
                            TrustBadge(state: .verified, size: .small)
                        }

                        // Product info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(reg.product.brand).font(.stCaption).foregroundStyle(Color.stSecondary)
                            Text(reg.product.name).font(.stTitle2).foregroundStyle(Color.stPrimary)
                            HStack {
                                Label(reg.product.category, systemImage: "shippingbox")
                                    .font(.stCaption).foregroundStyle(Color.stTertiary)
                                Spacer()
                                Text("SN: \(reg.product.serialNumber)").font(.stMonoSm).foregroundStyle(Color.stTertiary)
                            }
                        }

                        Divider().background(Color.white.opacity(0.1))

                        // Verification details
                        VStack(alignment: .leading, spacing: 6) {
                            detailRow("Manufacturer", reg.product.manufacturerDid.components(separatedBy: ":").last ?? "—")
                            detailRow("Verified At", reg.manufacturerVerifiedAt.formatted(style: .medium))
                            detailRow("Signature", Formatters.shortHash(reg.manufacturerSignature))
                            detailRow("QR Scan Count", "\(vm.totalScanCount)")
                            if let loc = vm.scanLocation {
                                detailRow("Scan Location", loc.formattedAddress)
                            }
                        }
                    }
                    .padding(16)
                }
            }

            mlAssessmentCard(assessment)
            scanCountSummaryCard

            // Custody chain
            CustodyChainView(chain: reg.product.custodyChain)

            // Scan history with locations
            if !vm.scanHistory.isEmpty {
                scanHistoryCard
            }

            // OTP + Claim Section
            if vm.claimedOwnership == nil {
                otpClaimSection
            } else {
                ownershipConfirmed
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: – OTP Claim Section

    private var otpClaimSection: some View {
        GlassCard(cornerRadius: 22, glowColor: Color.stCyan, glowOpacity: 0.06, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "key.fill").foregroundStyle(Color.stCyan).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Claim Ownership").font(.stHeadline).foregroundStyle(Color.stPrimary)
                        Text("Enter OTP to register as first owner").font(.stCaption).foregroundStyle(Color.stSecondary)
                    }
                }

                // Bill reference (optional)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bill / Receipt Reference").font(.stCaption).foregroundStyle(Color.stTertiary)
                    TextField("e.g. INV-2025-001234", text: $vm.billReference)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Color.stPrimary)
                        .padding(10)
                        .glassEffect(Glass.clear, in: .rect(cornerRadius: 10))
                }

                // Generate OTP button
                if vm.currentOTP == nil {
                    GlassButton(
                        label: "Generate OTP",
                        icon: "lock.rotation",
                        isLoading: vm.isGeneratingOTP,
                        fullWidth: true
                    ) {
                        vm.requestOTP()
                    }
                } else {
                    // OTP generated — show it + input field
                    GlassCard(cornerRadius: 16, glowColor: Color.stGold, glowOpacity: 0.08, innerPadding: 14) {
                        VStack(spacing: 10) {
                            Text("YOUR OTP").font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.stGold).tracking(1.5)
                            Text(vm.currentOTP?.code ?? "------")
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.stPrimary)
                                .tracking(8)
                            HStack(spacing: 4) {
                                Image(systemName: "clock").font(.caption2)
                                Text("Expires in \(vm.otpCountdownFormatted)").font(.stCaption)
                            }
                            .foregroundStyle(vm.otpCountdown < 60 ? Color.stRed : Color.stSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // OTP input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enter OTP to confirm").font(.stCaption).foregroundStyle(Color.stTertiary)
                        TextField("000000", text: $vm.otpInput)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.stPrimary)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .glassEffect(Glass.clear, in: .rect(cornerRadius: 12))
                            .onChange(of: vm.otpInput) { _, new in
                                vm.otpInput = String(new.prefix(6).filter { $0.isNumber })
                            }
                    }

                    if let err = vm.otpError {
                        Text(err).font(.stCaption).foregroundStyle(Color.stRed)
                    }

                    GlassButton(
                        label: "Claim Ownership",
                        icon: "hand.raised.fill",
                        isLoading: vm.isClaiming,
                        fullWidth: true
                    ) {
                        vm.validateAndClaim()
                    }
                }
            }
        }
    }

    // MARK: – Ownership Confirmed

    private var ownershipConfirmed: some View {
        GlassCard(cornerRadius: 24, glowColor: Color(hex: "00FF88"), glowOpacity: 0.15, innerPadding: 0) {
            VStack(spacing: 0) {
                Rectangle().fill(Color(hex: "00FF88")).frame(height: 3)
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color(hex: "00FF88").opacity(0.12)).frame(width: 64, height: 64)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 34)).foregroundStyle(Color(hex: "00FF88"))
                    }
                    .shadow(color: Color(hex: "00FF88").opacity(0.5), radius: 16)

                    Text("OWNERSHIP CLAIMED").font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "00FF88")).tracking(1.5)
                    Text("You are the first registered owner")
                        .font(.stBody).foregroundStyle(Color.stSecondary)

                    if let o = vm.claimedOwnership {
                        VStack(alignment: .leading, spacing: 6) {
                            detailRow("Owner DID", Formatters.shortDID(o.ownerDid))
                            detailRow("Claimed At", o.claimedAt.formatted(style: .medium))
                            if let loc = o.claimLocation {
                                detailRow("Location", loc.formattedAddress)
                            }
                            if let bill = o.billReference {
                                detailRow("Bill Ref", bill)
                            }
                        }
                    }

                    Text("This product now appears in your Wallet")
                        .font(.stCaption).foregroundStyle(Color.stTertiary)
                }
                .padding(20)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: – Counterfeit Result

    private func counterfeitResult(_ reason: String, assessment: ProductAuthenticityAssessment?) -> some View {
        VStack(spacing: 12) {
            GlassCard(cornerRadius: 24, glowColor: Color.stRed, glowOpacity: 0.15, innerPadding: 0) {
                VStack(spacing: 0) {
                    Rectangle().fill(Color.stRed).frame(height: 3)
                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color.stRed.opacity(0.12)).frame(width: 52, height: 52)
                                Image(systemName: "xmark.seal.fill")
                                    .font(.title2).foregroundStyle(Color.stRed)
                            }
                            .shadow(color: Color.stRed.opacity(0.4), radius: 10)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("COUNTERFEIT DETECTED").font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.stRed).tracking(1)
                                Text(reason).font(.stBodySm).foregroundStyle(Color.stSecondary)
                            }
                            Spacer()
                            TrustBadge(state: .revoked, size: .small)
                        }
                        Text("⚠️ Do NOT purchase this product. Report to the manufacturer.")
                            .font(.stCaption).foregroundStyle(Color.stRed.opacity(0.8))
                    }
                    .padding(16)
                }
            }
            scanCountSummaryCard
            if let assessment {
                mlAssessmentCard(assessment)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: – Unregistered

    private func unregisteredResult(assessment: ProductAuthenticityAssessment?) -> some View {
        VStack(spacing: 12) {
            GlassCard(cornerRadius: 24, glowColor: Color.stRed, glowOpacity: 0.18, innerPadding: 0) {
                VStack(spacing: 0) {
                    Rectangle().fill(Color.stRed).frame(height: 4)
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Color.stRed.opacity(0.15)).frame(width: 72, height: 72)
                            Image(systemName: "xmark.shield.fill")
                                .font(.system(size: 38)).foregroundStyle(Color.stRed)
                        }
                        .shadow(color: Color.stRed.opacity(0.5), radius: 16)

                        Text("⚠️ FAKE / NOT VERIFIED").font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.stRed).tracking(1.5)

                        Text("This product has NOT been verified by any manufacturer.\nIt is not registered in the authenticity registry.")
                            .font(.stBody).foregroundStyle(Color.stSecondary)
                            .multilineTextAlignment(.center)

                        Divider().background(Color.stRed.opacity(0.3))

                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.stRed)
                                Text("DO NOT purchase this product").font(.stHeadline).foregroundStyle(Color.stRed)
                            }
                            Text("No manufacturer has scanned and verified this product. This is likely a counterfeit item. Report to the brand's official support.")
                                .font(.stCaption).foregroundStyle(Color.stTertiary)
                                .multilineTextAlignment(.center)
                        }

                        TrustBadge(state: .revoked, size: .small)
                    }
                    .padding(20)
                }
            }
            scanCountSummaryCard
            if let assessment {
                mlAssessmentCard(assessment)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: – Already Owned

    private func alreadyOwnedResult(_ ownership: ProductOwnership, assessment: ProductAuthenticityAssessment?) -> some View {
        VStack(spacing: 12) {
            GlassCard(cornerRadius: 24, glowColor: Color.stBlue, glowOpacity: 0.10, innerPadding: 0) {
                VStack(spacing: 0) {
                    Rectangle().fill(Color.stBlue).frame(height: 3)
                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color.stBlue.opacity(0.12)).frame(width: 52, height: 52)
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.title2).foregroundStyle(Color.stBlue)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("ALREADY CLAIMED").font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.stBlue).tracking(1)
                                Text("This product has an existing owner")
                                    .font(.stBodySm).foregroundStyle(Color.stSecondary)
                            }
                            Spacer()
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            detailRow("Owner", Formatters.shortDID(ownership.ownerDid))
                            detailRow("Claimed", ownership.claimedAt.formatted(style: .medium))
                            if let loc = ownership.claimLocation {
                                detailRow("Location", loc.formattedAddress)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            scanCountSummaryCard
            if let assessment {
                mlAssessmentCard(assessment)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: – ML Assessment Card

    private func mlAssessmentCard(_ assessment: ProductAuthenticityAssessment) -> some View {
        let color: Color = switch assessment.riskLevel {
        case .low: .init(hex: "00FF88")
        case .medium: .stGold
        case .high: .stOrange
        case .critical: .stRed
        }

        return GlassCard(cornerRadius: 20, glowColor: color, glowOpacity: 0.10, innerPadding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("On-device ML Authenticity Score")
                            .font(.stHeadline).foregroundStyle(Color.stPrimary)
                        Text("Model \(assessment.modelVersion) • Confidence \(assessment.confidence)%")
                            .font(.stCaption).foregroundStyle(Color.stSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(assessment.score)/100")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(color)
                        Text(assessment.riskLevel.label.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(color)
                    }
                }

                if !assessment.reasons.isEmpty {
                    Divider().background(Color.white.opacity(0.1))
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(assessment.reasons.prefix(3).enumerated()), id: \.offset) { _, reason in
                            Text("• \(reason)")
                                .font(.stCaption)
                                .foregroundStyle(Color.stTertiary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    // MARK: – Shared

    private var scanCountSummaryCard: some View {
        GlassCard(cornerRadius: 16, glowColor: Color.stCyan, glowOpacity: 0.05, innerPadding: 12) {
            HStack(spacing: 10) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Color.stCyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("QR Scan Telemetry")
                        .font(.stCaption)
                        .foregroundStyle(Color.stSecondary)
                    Text("Total: \(vm.totalScanCount)  •  Manufacturer: \(vm.manufacturerScanCount)  •  Consumer: \(vm.consumerScanCount)")
                        .font(.stMonoSm)
                        .foregroundStyle(Color.stPrimary)
                }
                Spacer()
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.stCaption).foregroundStyle(Color.stTertiary)
            Text(value).font(.stMono).foregroundStyle(Color.stSecondary).lineLimit(2)
        }
    }

    // MARK: – Scan History Card

    private var scanHistoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scan History").font(.stHeadline).foregroundStyle(Color.stPrimary)

            // Map showing scan locations
            let withLoc = vm.scanHistory.compactMap { event -> (ProductScanEvent, ProductLocation)? in
                guard let loc = event.location else { return nil }
                return (event, loc)
            }

            if !withLoc.isEmpty {
                GlassCard(cornerRadius: 16, innerPadding: 0) {
                    let coords = withLoc.map { CLLocationCoordinate2D(latitude: $0.1.latitude, longitude: $0.1.longitude) }
                    let center = CLLocationCoordinate2D(
                        latitude: coords.map(\.latitude).reduce(0, +) / Double(coords.count),
                        longitude: coords.map(\.longitude).reduce(0, +) / Double(coords.count)
                    )
                    Map(initialPosition: .region(MKCoordinateRegion(center: center,
                        latitudinalMeters: coords.count == 1 ? 1000 : 50000,
                        longitudinalMeters: coords.count == 1 ? 1000 : 50000))) {
                        ForEach(withLoc, id: \.0.id) { event, loc in
                            Marker(
                                event.actor == .manufacturer ? "Manufacturer" : "Consumer",
                                coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                            )
                            .tint(event.actor == .manufacturer ? Color(hex: "00FF88") : Color(hex: "22D3EE"))
                        }
                    }
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .allowsHitTesting(false)
                }
            }

            // Timeline
            GlassCard(cornerRadius: 18, innerPadding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(vm.scanHistory) { event in
                        HStack(spacing: 10) {
                            Circle()
                                .fill((event.actor == .manufacturer ? Color(hex: "00FF88") : Color(hex: "22D3EE")).opacity(0.15))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: event.actor == .manufacturer ? "building.2.fill" : "person.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(event.actor == .manufacturer ? Color(hex: "00FF88") : Color(hex: "22D3EE"))
                                )
                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.actor == .manufacturer ? "Manufacturer" : "Consumer")
                                    .font(.stCaption).foregroundStyle(Color.stPrimary)
                                if let loc = event.location {
                                    Text(loc.formattedAddress).font(.stMonoSm).foregroundStyle(Color.stSecondary)
                                }
                                Text(event.scannedAt.formatted(style: .short))
                                    .font(.stMonoSm).foregroundStyle(Color.stTertiary)
                                if let score = event.authenticityScore {
                                    let risk = event.riskLevel?.label.uppercased() ?? "UNKNOWN"
                                    Text("ML Score: \(score)/100 • \(risk)")
                                        .font(.stMonoSm)
                                        .foregroundStyle(Color.stCyan)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
