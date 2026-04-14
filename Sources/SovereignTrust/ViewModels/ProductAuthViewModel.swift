import Foundation
import Observation
import CoreLocation

// MARK: – Product Auth ViewModel
// Drives: scan → verify → OTP → claim → wallet
// Uses real GPS location via LocationService — no simulation.

@Observable
@MainActor
final class ProductAuthViewModel {

    // MARK: – State

    /// Verification result after QR scan.
    var verificationStatus: ProductVerificationStatus?
    var isVerifying = false
    var latestAssessment: ProductAuthenticityAssessment?

    /// The scanned product (if authentic).
    var scannedProduct: RegisteredProduct?

    /// OTP state.
    var currentOTP: ProductOTP?
    var otpInput = ""
    var otpError: String?
    var isGeneratingOTP = false
    var otpCountdown: Int = 0

    /// Ownership state.
    var claimedOwnership: ProductOwnership?
    var isClaiming = false
    var billReference = ""

    /// Wallet — owned products.
    var ownedProducts: [(RegisteredProduct, ProductOwnership)] = []
    var isLoadingWallet = false

    /// Real location from GPS.
    var scanLocation: ProductLocation?
    var isResolvingLocation = false
    var locationError: String?

    /// Scan history for current product.
    var scanHistory: [ProductScanEvent] = []
    var totalScanCount = 0
    var manufacturerScanCount = 0
    var consumerScanCount = 0
    var currentProductId: String?

    /// Current raw QR payload for display.
    var lastRawPayload: String?

    /// Timer for OTP countdown.
    private var otpTimer: Timer?

    // MARK: – Location

    /// Resolves real GPS location before verification.
    func resolveLocation() async {
        isResolvingLocation = true
        locationError = nil
        let location = await LocationService.shared.resolveCurrentLocation()
        self.scanLocation = location
        self.isResolvingLocation = false
        if location == nil {
            locationError = "Location unavailable — enable Location Services in Settings"
        }
    }

    // MARK: – Verify Product (consumer scans QR)

    func verifyProduct(rawPayload: String) {
        isVerifying = true
        lastRawPayload = rawPayload
        reset()

        let parsed = QRParserService.parse(rawPayload)
        guard parsed.type == .product, let payload = parsed.payload, !payload.id.isEmpty else {
            verificationStatus = .counterfeit(reason: "Invalid product QR format", nil)
            isVerifying = false
            return
        }

        let productId = payload.id
        let serial = payload.serial
        currentProductId = productId

        Task {
            // Get real location first
            await resolveLocation()

            let status = await ProductAuthService.shared.verifyProduct(
                id: productId,
                serial: serial,
                rawPayload: rawPayload,
                location: scanLocation,
                scannerDid: Identity.mock.did
            )
            self.verificationStatus = status

            let history = await ProductAuthService.shared.scanHistory(for: productId)
            self.scanHistory = history
            self.updateScanCounts(from: history)

            switch status {
            case .authentic(let reg, let assessment):
                self.scannedProduct = reg
                self.latestAssessment = assessment
            case .alreadyOwned(_, let assessment):
                self.scannedProduct = nil
                self.latestAssessment = assessment
            case .counterfeit(_, let assessment):
                self.scannedProduct = nil
                self.latestAssessment = assessment
            case .unregistered(let assessment):
                self.scannedProduct = nil
                self.latestAssessment = assessment
            }
            self.isVerifying = false
        }
    }

    // MARK: – OTP Flow

    func requestOTP() {
        guard let product = scannedProduct else { return }
        isGeneratingOTP = true
        otpError = nil

        Task {
            let otp = await ProductAuthService.shared.generateOTP(for: product.id)
            self.currentOTP = otp
            self.isGeneratingOTP = false
            if otp != nil {
                startOTPCountdown()
            } else {
                self.otpError = "Could not generate OTP — product may already be claimed"
            }
        }
    }

    func validateAndClaim() {
        guard let product = scannedProduct else { return }
        guard otpInput.count == 6 else {
            otpError = "Enter the 6-digit OTP"
            return
        }
        isClaiming = true
        otpError = nil

        Task {
            // Resolve latest location for claim
            if scanLocation == nil {
                await resolveLocation()
            }

            let ownership = await ProductAuthService.shared.claimOwnership(
                productId: product.id,
                otpCode: otpInput,
                ownerDid: Identity.mock.did,
                location: scanLocation,
                billReference: billReference.isEmpty ? nil : billReference
            )
            if let ownership {
                self.claimedOwnership = ownership
                self.stopOTPTimer()
            } else {
                self.otpError = "Invalid or expired OTP. Try again."
            }
            self.isClaiming = false
        }
    }

    // MARK: – Wallet

    func loadWallet() {
        isLoadingWallet = true
        Task {
            let items = await ProductAuthService.shared.ownedProducts(for: Identity.mock.did)
            self.ownedProducts = items
            self.isLoadingWallet = false
        }
    }

    // MARK: – Scan History

    func loadScanHistory(for productId: String) {
        Task {
            let history = await ProductAuthService.shared.scanHistory(for: productId)
            self.scanHistory = history
            self.updateScanCounts(from: history)
        }
    }

    // MARK: – Helpers

    func reset() {
        verificationStatus = nil
        scannedProduct = nil
        currentOTP = nil
        otpInput = ""
        otpError = nil
        claimedOwnership = nil
        latestAssessment = nil
        billReference = ""
        scanHistory = []
        totalScanCount = 0
        manufacturerScanCount = 0
        consumerScanCount = 0
        currentProductId = nil
        stopOTPTimer()
    }

    private func updateScanCounts(from history: [ProductScanEvent]) {
        totalScanCount = history.count
        manufacturerScanCount = history.filter { $0.actor == .manufacturer }.count
        consumerScanCount = history.filter { $0.actor == .consumer }.count
    }

    private func startOTPCountdown() {
        otpCountdown = 300 // 5 minutes
        otpTimer?.invalidate()
        otpTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { timer.invalidate(); return }
                if self.otpCountdown > 0 {
                    self.otpCountdown -= 1
                } else {
                    timer.invalidate()
                    self.otpError = "OTP expired. Request a new one."
                    self.currentOTP = nil
                }
            }
        }
    }

    private func stopOTPTimer() {
        otpTimer?.invalidate()
        otpTimer = nil
        otpCountdown = 0
    }

    var otpCountdownFormatted: String {
        let m = otpCountdown / 60
        let s = otpCountdown % 60
        return String(format: "%d:%02d", m, s)
    }
}
