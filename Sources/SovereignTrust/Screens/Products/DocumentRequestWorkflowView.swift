import SwiftUI
import UIKit

private enum DocumentWorkflowRole: String, CaseIterable, Identifiable {
    case requester
    case holder

    var id: String { rawValue }

    var label: String {
        switch self {
        case .requester: return "Requester"
        case .holder: return "Holder"
        }
    }

    var subtitle: String {
        switch self {
        case .requester: return "Create request QR and verify response"
        case .holder: return "Scan request and return signed response"
        }
    }
}

struct DocumentRequestWorkflowView: View {
    @State private var appState = AppState.shared
    @State private var role: DocumentWorkflowRole = .requester

    // Shared real-world context
    @State private var actionLocation: ProductLocation?
    @State private var isResolvingLocation = false
    @State private var locationError: String?

    // Requester state
    @State private var selectedTypes: Set<CredentialType> = [.identity, .education, .professional]
    @State private var requestPayload: DocumentRequestPayload?
    @State private var requestQRImage: UIImage?
    @State private var confirmation: DocumentRequestConfirmation?
    @State private var requesterError: String?
    @State private var isCreatingRequest = false
    @State private var showResponseScanner = false

    // Holder state
    @State private var showRequestScanner = false
    @State private var scannedRequest: DocumentRequestPayload?
    @State private var consentMode: DocumentConsentMode = .verifyOnly
    @State private var responsePayload: DocumentResponsePayload?
    @State private var responseQRImage: UIImage?
    @State private var holderError: String?
    @State private var isGeneratingResponse = false

    @State private var credentialVM = CredentialViewModel()
    @State private var holderCredentials: [Credential] = []

    private var dark: Bool { appState.isDarkMode }

    private var selectableTypes: [CredentialType] {
        [.identity, .education, .professional, .membership, .document, .product]
    }

    var body: some View {
        ZStack {
            AmbientBackground(isDark: dark).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    roleSelector
                    locationCard

                    if role == .requester {
                        requesterSection
                    } else {
                        holderSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("File Request QR")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showResponseScanner) {
            ProductScannerSheet { payload in
                showResponseScanner = false
                Task { await processScannedResponse(payload) }
            }
        }
        .sheet(isPresented: $showRequestScanner) {
            ProductScannerSheet { payload in
                showRequestScanner = false
                Task { await processScannedRequest(payload) }
            }
        }
        .task {
            LocationService.shared.requestPermission()
            await resolveLocation()
            await loadHolderCredentials()
        }
    }

    // MARK: – Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Requester ↔ Holder Workflow")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.primary(dark: dark))
            Text(role.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.secondary(dark: dark))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var roleSelector: some View {
        GlassCard(cornerRadius: 16, innerPadding: 10) {
            Picker("Role", selection: $role) {
                ForEach(DocumentWorkflowRole.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var locationCard: some View {
        GlassCard(
            cornerRadius: 18,
            glowColor: actionLocation != nil ? Color(hex: "00FF88") : Color.stOrange,
            glowOpacity: 0.07,
            innerPadding: 12
        ) {
            HStack(spacing: 10) {
                if isResolvingLocation {
                    ProgressView().tint(Color.stCyan)
                } else {
                    Image(systemName: actionLocation != nil ? "location.fill" : "location.slash")
                        .foregroundStyle(actionLocation != nil ? Color(hex: "00FF88") : Color.stOrange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Real Location Context")
                        .font(.stHeadline)
                        .foregroundStyle(Color.stPrimary)
                    if let loc = actionLocation {
                        Text(loc.formattedAddress)
                            .font(.stCaption)
                            .foregroundStyle(Color.stSecondary)
                    } else if let locationError {
                        Text(locationError)
                            .font(.stCaption)
                            .foregroundStyle(Color.stOrange)
                    } else {
                        Text("Resolving current GPS coordinates")
                            .font(.stCaption)
                            .foregroundStyle(Color.stSecondary)
                    }
                }
                Spacer()
                if !isResolvingLocation {
                    Button("Refresh") {
                        Task { await resolveLocation() }
                    }
                    .font(.stCaption)
                    .foregroundStyle(Color.stCyan)
                }
            }
        }
    }

    // MARK: – Requester

    private var requesterSection: some View {
        VStack(spacing: 12) {
            GlassCard(cornerRadius: 22, innerPadding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Requested File Types")
                        .font(.stHeadline)
                        .foregroundStyle(Color.stPrimary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(selectableTypes, id: \.self) { type in
                            requestTypeChip(type)
                        }
                    }

                    GlassButton(
                        label: "Create Request QR",
                        icon: "qrcode",
                        isLoading: isCreatingRequest,
                        fullWidth: true
                    ) {
                        Task { await createRequestQR() }
                    }
                }
            }

            if let requestPayload, let requestQRImage {
                requesterQRCard(payload: requestPayload, image: requestQRImage)
            }

            if let confirmation {
                confirmationCard(confirmation)
            }

            if let requesterError {
                errorCard(requesterError)
            }
        }
    }

    private func requestTypeChip(_ type: CredentialType) -> some View {
        let selected = selectedTypes.contains(type)
        return Button {
            if selected {
                selectedTypes.remove(type)
            } else {
                selectedTypes.insert(type)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                Text(type.label)
                    .font(.stCaption)
            }
            .foregroundStyle(selected ? Color.stCyan : Color.stSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 8)
            .glassButton(glow: selected ? Color.stCyan : .clear, glowIntensity: selected ? 0.12 : 0)
        }
        .buttonStyle(.plain)
    }

    private func requesterQRCard(payload: DocumentRequestPayload, image: UIImage) -> some View {
        GlassCard(cornerRadius: 24, glowColor: Color.stCyan, glowOpacity: 0.10, innerPadding: 16) {
            VStack(spacing: 12) {
                Text("Request QR Ready")
                    .font(.stHeadline)
                    .foregroundStyle(Color.stPrimary)
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    detailRow("Request ID", String(payload.requestId.prefix(12)).uppercased())
                    detailRow("Requested Files", "\(payload.items.count)")
                    detailRow("Expires", Date(timeIntervalSince1970: TimeInterval(payload.expiresAt)).formatted(style: .short))
                }

                HStack(spacing: 10) {
                    GlassButton(label: "Scan Response", icon: "qrcode.viewfinder", fullWidth: true) {
                        showResponseScanner = true
                    }
                    GlassButton(label: "Share", icon: "square.and.arrow.up") {
                        shareImage(image)
                    }
                }
            }
        }
    }

    private func confirmationCard(_ confirmation: DocumentRequestConfirmation) -> some View {
        GlassCard(
            cornerRadius: 24,
            glowColor: confirmation.allVerified ? Color(hex: "00FF88") : Color.stOrange,
            glowOpacity: 0.11,
            innerPadding: 16
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: confirmation.allVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(confirmation.allVerified ? Color(hex: "00FF88") : Color.stOrange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Batch Confirmation")
                            .font(.stHeadline)
                            .foregroundStyle(Color.stPrimary)
                        Text(confirmation.summary)
                            .font(.stCaption)
                            .foregroundStyle(Color.stSecondary)
                    }
                    Spacer()
                    Text(confirmation.consentMode.label)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.stCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.stCyan.opacity(0.14))
                        .clipShape(Capsule())
                }

                Divider().background(Color.white.opacity(0.1))

                ForEach(confirmation.items) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.status == .verified ? "checkmark.circle.fill" : item.status == .missing ? "minus.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(item.status == .verified ? Color(hex: "00FF88") : item.status == .missing ? Color.stGold : Color.stRed)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(.stCaption)
                                .foregroundStyle(Color.stPrimary)
                            Text(item.note)
                                .font(.stMonoSm)
                                .foregroundStyle(Color.stTertiary)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                }

                if let loc = confirmation.responseLocation {
                    Divider().background(Color.white.opacity(0.1))
                    detailRow("Responder Location", loc.formattedAddress)
                }
            }
        }
    }

    // MARK: – Holder

    private var holderSection: some View {
        VStack(spacing: 12) {
            GlassCard(cornerRadius: 22, innerPadding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scan Request")
                        .font(.stHeadline)
                        .foregroundStyle(Color.stPrimary)

                    GlassButton(label: "Scan Request QR", icon: "qrcode.viewfinder", fullWidth: true) {
                        showRequestScanner = true
                    }
                }
            }

            if let request = scannedRequest {
                holderRequestCard(request)
            }

            if let responsePayload, let responseQRImage {
                holderResponseCard(payload: responsePayload, image: responseQRImage)
            }

            if let holderError {
                errorCard(holderError)
            }
        }
    }

    private func holderRequestCard(_ request: DocumentRequestPayload) -> some View {
        GlassCard(cornerRadius: 24, glowColor: Color.stGold, glowOpacity: 0.10, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Incoming Request")
                    .font(.stHeadline)
                    .foregroundStyle(Color.stPrimary)

                detailRow("Requester", request.requesterName)
                detailRow("Request ID", String(request.requestId.prefix(12)).uppercased())
                detailRow("Expires", Date(timeIntervalSince1970: TimeInterval(request.expiresAt)).formatted(style: .short))

                Divider().background(Color.white.opacity(0.1))

                ForEach(request.items) { item in
                    let match = bestCredential(for: item.type)
                    HStack(spacing: 8) {
                        Image(systemName: match == nil ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(match == nil ? Color.stRed : Color(hex: "00FF88"))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(.stCaption)
                                .foregroundStyle(Color.stPrimary)
                            if let match {
                                Text("Matched: \(match.title)")
                                    .font(.stMonoSm)
                                    .foregroundStyle(Color.stSecondary)
                            } else {
                                Text("No matching credential")
                                    .font(.stMonoSm)
                                    .foregroundStyle(Color.stRed)
                            }
                        }
                        Spacer()
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Consent Mode")
                        .font(.stCaption)
                        .foregroundStyle(Color.stTertiary)
                    Picker("Consent", selection: $consentMode) {
                        ForEach(DocumentConsentMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(consentMode.detail)
                        .font(.stMonoSm)
                        .foregroundStyle(Color.stSecondary)
                }

                GlassButton(
                    label: "Sign & Generate Response QR",
                    icon: "checkmark.shield.fill",
                    isLoading: isGeneratingResponse,
                    fullWidth: true
                ) {
                    Task { await generateResponseQR() }
                }
            }
        }
    }

    private func holderResponseCard(payload: DocumentResponsePayload, image: UIImage) -> some View {
        let verifiedCount = payload.items.filter { $0.status == .verified }.count
        let failedCount = payload.items.filter { $0.status == .failed }.count
        let missingCount = payload.items.filter { $0.status == .missing }.count

        return GlassCard(cornerRadius: 24, glowColor: Color.stCyan, glowOpacity: 0.10, innerPadding: 16) {
            VStack(spacing: 12) {
                Text("Signed Response QR")
                    .font(.stHeadline)
                    .foregroundStyle(Color.stPrimary)

                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                detailRow("Mode", payload.consentMode.label)
                detailRow("Verified", "\(verifiedCount)")
                detailRow("Failed", "\(failedCount)")
                detailRow("Missing", "\(missingCount)")

                GlassButton(label: "Share Response QR", icon: "square.and.arrow.up", fullWidth: true) {
                    shareImage(image)
                }
            }
        }
    }

    // MARK: – Helpers

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.stCaption)
                .foregroundStyle(Color.stTertiary)
            Text(value)
                .font(.stMono)
                .foregroundStyle(Color.stSecondary)
                .lineLimit(2)
        }
    }

    private func errorCard(_ text: String) -> some View {
        GlassCard(cornerRadius: 18, glowColor: Color.stRed, glowOpacity: 0.10, innerPadding: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.stRed)
                Text(text).font(.stCaption).foregroundStyle(Color.stSecondary)
                Spacer()
            }
        }
    }

    private func bestCredential(for type: CredentialType) -> Credential? {
        holderCredentials
            .filter { $0.type == type }
            .sorted { $0.issuedAt > $1.issuedAt }
            .first
    }

    private func resolveLocation() async {
        isResolvingLocation = true
        locationError = nil
        let loc = await LocationService.shared.resolveCurrentLocation()
        actionLocation = loc
        isResolvingLocation = false
        if loc == nil {
            locationError = "Location unavailable. Enable Location Services for real GPS evidence."
        }
    }

    private func loadHolderCredentials() async {
        await credentialVM.load(subjectDid: Identity.mock.did)
        holderCredentials = credentialVM.items.map(\.credential)
    }

    private func createRequestQR() async {
        requesterError = nil
        confirmation = nil
        isCreatingRequest = true

        if selectedTypes.isEmpty {
            requesterError = "Select at least one file type"
            isCreatingRequest = false
            return
        }

        if actionLocation == nil {
            await resolveLocation()
        }

        let types = selectableTypes.filter { selectedTypes.contains($0) }
        let output = await DocumentExchangeService.shared.createRequest(
            requester: Identity.mock,
            requestedTypes: types,
            location: actionLocation,
            validityMinutes: 10
        )

        requestPayload = output.payload
        requestQRImage = QRGeneratorService.generate(from: output.qrPayload, size: 280)
        if requestQRImage == nil {
            requesterError = "Failed to render request QR"
        }

        isCreatingRequest = false
    }

    private func processScannedResponse(_ raw: String) async {
        requesterError = nil
        guard let request = requestPayload else {
            requesterError = "Create a request before scanning response"
            return
        }
        guard let result = await DocumentExchangeService.shared.confirmResponse(request: request, rawResponse: raw) else {
            requesterError = "Invalid response QR payload"
            return
        }
        confirmation = result
    }

    private func processScannedRequest(_ raw: String) async {
        holderError = nil
        responsePayload = nil
        responseQRImage = nil

        guard let request = await DocumentExchangeService.shared.parseRequest(raw: raw) else {
            holderError = "Invalid request QR payload"
            return
        }

        scannedRequest = request
        await loadHolderCredentials()
    }

    private func generateResponseQR() async {
        holderError = nil

        guard let request = scannedRequest else {
            holderError = "Scan a request QR first"
            return
        }

        if request.isExpired {
            holderError = "Request has already expired"
            return
        }

        isGeneratingResponse = true

        do {
            let ok = try await BiometricService.shared.authenticate(reason: "Approve document request and sign response")
            guard ok else {
                holderError = "Biometric confirmation cancelled"
                isGeneratingResponse = false
                return
            }

            if actionLocation == nil {
                await resolveLocation()
            }

            let result = try await DocumentExchangeService.shared.buildResponse(
                request: request,
                holder: Identity.mock,
                holderCredentials: holderCredentials,
                consentMode: consentMode,
                location: actionLocation
            )

            responsePayload = result.payload
            responseQRImage = QRGeneratorService.generate(from: result.qrPayload, size: 280)
            if responseQRImage == nil {
                holderError = "Response signed, but QR rendering failed"
            }
        } catch {
            holderError = error.localizedDescription
        }

        isGeneratingResponse = false
    }

    private func shareImage(_ image: UIImage) {
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activity, animated: true)
        }
    }
}
