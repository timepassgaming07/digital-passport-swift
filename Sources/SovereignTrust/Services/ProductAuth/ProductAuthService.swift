import Foundation
import CryptoKit

// MARK: – Product Authentication Service
// On-device product registry, verification, OTP, and ownership transfer.
// All data persists to JSON files on disk. Real location + real OTP — no stubs.

actor ProductAuthService {
    static let shared = ProductAuthService()
    private init() {}

    // MARK: – Storage

    /// Products registered by manufacturers (keyed by product ID).
    private var registry: [String: RegisteredProduct] = [:]

    /// Ownership claims (keyed by product ID).
    private var ownerships: [String: ProductOwnership] = [:]

    /// Active OTPs (keyed by product ID).
    private var activeOTPs: [String: ProductOTP] = [:]

    /// Scan audit trail — real locations, real timestamps.
    private var scanEvents: [ProductScanEvent] = []

    /// Swift 6-safe lazy load flag (actor-isolated).
    private var hasLoadedFromDisk = false

    // MARK: – Persistence Paths

    private static var docsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private static var registryURL: URL { docsDir.appendingPathComponent("product_registry.json") }
    private static var ownershipsURL: URL { docsDir.appendingPathComponent("product_ownerships.json") }
    private static var scanEventsURL: URL { docsDir.appendingPathComponent("product_scan_events.json") }

    // MARK: – Load / Save

    private func loadFromDisk() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: Self.registryURL),
           let loaded = try? decoder.decode([String: RegisteredProduct].self, from: data) {
            registry = loaded
        }
        if let data = try? Data(contentsOf: Self.ownershipsURL),
           let loaded = try? decoder.decode([String: ProductOwnership].self, from: data) {
            ownerships = loaded
        }
        if let data = try? Data(contentsOf: Self.scanEventsURL),
           let loaded = try? decoder.decode([ProductScanEvent].self, from: data) {
            scanEvents = loaded
        }
    }

    private func ensureLoaded() {
        guard !hasLoadedFromDisk else { return }
        loadFromDisk()
        hasLoadedFromDisk = true
    }

    private func saveToDisk() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(registry) {
            try? data.write(to: Self.registryURL, options: .atomic)
        }
        if let data = try? encoder.encode(ownerships) {
            try? data.write(to: Self.ownershipsURL, options: .atomic)
        }
        if let data = try? encoder.encode(scanEvents) {
            try? data.write(to: Self.scanEventsURL, options: .atomic)
        }
    }

    // MARK: – Manufacturer Flow

    /// Manufacturer registers and verifies a product with real location.
    /// This is the "first scan" — location is captured via GPS on the manufacturer's device.
    func registerProduct(
        _ product: Product,
        location: ProductLocation? = nil,
        manufacturerDid: String? = nil,
        rawPayload: String? = nil
    ) async -> RegisteredProduct {
        ensureLoaded()

        let parsedPayload = rawPayload.flatMap { QRParserService.parse($0).payload }
        let resolvedDid = manufacturerDid ?? parsedPayload?.did ?? product.manufacturerDid
        let canonicalHash = Self.canonicalProductFingerprint(
            id: product.id,
            serial: parsedPayload?.serial ?? product.serialNumber,
            manufacturerDid: resolvedDid,
            brand: parsedPayload?.brand ?? product.brand,
            title: parsedPayload?.title ?? product.name
        )
        let sig = "mfr-sig:\(String(canonicalHash.prefix(16)))"
        var registered = RegisteredProduct(
            id: product.id,
            product: product,
            manufacturerVerifiedAt: Date(),
            manufacturerSignature: sig,
            qrHash: canonicalHash,
            manufacturerLocation: location,
            manufacturerDid: resolvedDid,
            latestAssessment: nil
        )

        let baselineAssessment = await ProductAuthenticityMLService.shared.evaluate(
            rawPayload: rawPayload ?? product.id,
            productId: product.id,
            serial: product.serialNumber,
            registered: registered,
            scanLocation: location,
            history: scanHistory(for: product.id)
        )
        registered.latestAssessment = baselineAssessment
        registry[product.id] = registered

        // Record the manufacturer's first scan event
        let event = ProductScanEvent(
            id: UUID().uuidString,
            productId: product.id,
            scannedAt: Date(),
            location: location,
            result: "manufacturer_verified",
            actor: .manufacturer,
            scannerDid: resolvedDid,
            authenticityScore: baselineAssessment.score,
            riskLevel: baselineAssessment.riskLevel,
            dominantSignal: baselineAssessment.signals.first?.key
        )
        scanEvents.append(event)
        saveToDisk()

        return registered
    }

    /// Check if a product is already registered.
    func isRegistered(_ productId: String) -> Bool {
        ensureLoaded()
        return registry[productId] != nil
    }

    /// Get a registered product by ID.
    func registeredProduct(_ productId: String) -> RegisteredProduct? {
        ensureLoaded()
        return registry[productId]
    }

    // MARK: – Consumer Verification Flow

    /// Consumer scans a product QR and verifies it against the registry.
    /// Location is captured via real GPS on the consumer's device.
    func verifyProduct(
        id: String,
        serial: String?,
        rawPayload: String,
        location: ProductLocation?,
        scannerDid: String? = nil
    ) async -> ProductVerificationStatus {
        ensureLoaded()

        let parsed = QRParserService.parse(rawPayload)
        let payload = parsed.payload
        let existingHistory = scanHistory(for: id)
        let registryProduct = registry[id]
        let hasManufacturerProof = scanEvents.contains {
            $0.productId == id && $0.actor == .manufacturer && $0.result == "manufacturer_verified"
        }
        let hasDynamicIntegrity = Self.hasValidDynamicIntegrity(payload)

        let assessment = await ProductAuthenticityMLService.shared.evaluate(
            rawPayload: rawPayload,
            productId: id,
            serial: serial,
            registered: registryProduct,
            scanLocation: location,
            history: existingHistory
        )

        let status: ProductVerificationStatus
        let eventResult: String

        if id.isEmpty || parsed.type != .product {
            status = .counterfeit(reason: "Invalid product QR payload", assessment)
            eventResult = "counterfeit_invalid_payload"
        } else if let payload, payload.id != id {
            status = .counterfeit(reason: "QR product ID mismatch", assessment)
            eventResult = "counterfeit_id_mismatch"
        } else if let ownership = ownerships[id] {
            status = .alreadyOwned(ownership, assessment)
            eventResult = "already_owned"
        } else if registryProduct == nil {
            status = .unregistered(assessment)
            eventResult = "unregistered"
        } else if let registered = registryProduct {
            if !hasManufacturerProof {
                status = .counterfeit(
                    reason: "Product is not verified by manufacturer yet",
                    assessment
                )
                eventResult = "counterfeit_not_manufacturer_verified"
            } else if !hasDynamicIntegrity {
                status = .counterfeit(
                    reason: "QR integrity check failed (nonce/hash mismatch)",
                    assessment
                )
                eventResult = "counterfeit_qr_integrity"
            } else if let serial, serial.caseInsensitiveCompare(registered.product.serialNumber) != .orderedSame {
                status = .counterfeit(
                    reason: "Serial number mismatch: expected \(registered.product.serialNumber)",
                    assessment
                )
                eventResult = "counterfeit_serial_mismatch"
            } else if assessment.score < 45 || assessment.riskLevel == .critical {
                status = .counterfeit(
                    reason: "High QR anomaly risk detected (score \(assessment.score)/100)",
                    assessment
                )
                eventResult = "counterfeit_ml_risk"
            } else {
                var updated = registered
                updated.latestAssessment = assessment
                registry[id] = updated
                status = .authentic(updated, assessment)
                eventResult = "authentic"
            }
        } else {
            status = .unregistered(assessment)
            eventResult = "unregistered"
        }

        let event = ProductScanEvent(
            id: UUID().uuidString,
            productId: id,
            scannedAt: Date(),
            location: location,
            result: eventResult,
            actor: .consumer,
            scannerDid: scannerDid,
            authenticityScore: assessment.score,
            riskLevel: assessment.riskLevel,
            dominantSignal: assessment.signals.first?.key
        )
        scanEvents.append(event)
        saveToDisk()

        return status
    }

    // MARK: – OTP + Ownership Flow

    /// Generate an OTP for claiming ownership (cryptographically random).
    func generateOTP(for productId: String) -> ProductOTP? {
        ensureLoaded()

        guard registry[productId] != nil else { return nil }
        guard ownerships[productId] == nil else { return nil }
        let otp = ProductOTP.generate(for: productId)
        activeOTPs[productId] = otp
        return otp
    }

    /// Validate OTP and transfer ownership to the user.
    func claimOwnership(
        productId: String,
        otpCode: String,
        ownerDid: String,
        location: ProductLocation?,
        billReference: String?
    ) -> ProductOwnership? {
        ensureLoaded()

        guard let otp = activeOTPs[productId] else { return nil }
        guard otp.code == otpCode else { return nil }
        guard !otp.isExpired else {
            activeOTPs.removeValue(forKey: productId)
            return nil
        }

        let ownership = ProductOwnership(
            id: UUID().uuidString,
            productId: productId,
            ownerDid: ownerDid,
            claimedAt: Date(),
            claimLocation: location,
            billReference: billReference,
            isFirstOwner: true
        )
        ownerships[productId] = ownership
        activeOTPs.removeValue(forKey: productId)
        saveToDisk()
        return ownership
    }

    // MARK: – Wallet Queries

    /// Get all products owned by a DID.
    func ownedProducts(for did: String) -> [(RegisteredProduct, ProductOwnership)] {
        ensureLoaded()

        return ownerships.values
            .filter { $0.ownerDid == did }
            .compactMap { ownership in
                guard let reg = registry[ownership.productId] else { return nil }
                return (reg, ownership)
            }
            .sorted { $0.1.claimedAt > $1.1.claimedAt }
    }

    /// Get scan history for a product — includes manufacturer first scan + all consumer scans.
    func scanHistory(for productId: String) -> [ProductScanEvent] {
        ensureLoaded()

        return scanEvents
            .filter { $0.productId == productId }
            .sorted { $0.scannedAt < $1.scannedAt }
    }

    func scanCount(for productId: String) -> Int {
        ensureLoaded()
        return scanEvents.filter { $0.productId == productId }.count
    }

    func manufacturerScanCount(for productId: String) -> Int {
        ensureLoaded()
        return scanEvents.filter { $0.productId == productId && $0.actor == .manufacturer }.count
    }

    func consumerScanCount(for productId: String) -> Int {
        ensureLoaded()
        return scanEvents.filter { $0.productId == productId && $0.actor == .consumer }.count
    }

    /// Get active OTP for display.
    func currentOTP(for productId: String) -> ProductOTP? {
        ensureLoaded()

        guard let otp = activeOTPs[productId], !otp.isExpired else { return nil }
        return otp
    }

    /// Get all registered products (for manufacturer dashboard).
    func allRegisteredProducts() -> [RegisteredProduct] {
        ensureLoaded()

        return Array(registry.values).sorted { $0.manufacturerVerifiedAt > $1.manufacturerVerifiedAt }
    }

    private static func sha256Hex(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func canonicalProductFingerprint(
        id: String,
        serial: String,
        manufacturerDid: String,
        brand: String,
        title: String
    ) -> String {
        sha256Hex("\(id)|\(serial.lowercased())|\(manufacturerDid.lowercased())|\(brand.lowercased())|\(title.lowercased())")
    }

    private static func dynamicPayloadHash(id: String, serial: String, did: String, nonce: String, ts: String) -> String {
        sha256Hex("\(id)|\(serial)|\(did)|\(nonce.lowercased())|\(ts)")
    }

    private static func hasValidDynamicIntegrity(_ payload: QRPayload?) -> Bool {
        guard let payload else { return false }
        guard let nonce = payload.nonce, !nonce.isEmpty else { return false }
        guard !payload.ts.isEmpty else { return false }

        let expected = dynamicPayloadHash(
            id: payload.id,
            serial: payload.serial ?? "",
            did: payload.did,
            nonce: nonce,
            ts: payload.ts
        )
        return payload.hash.lowercased() == expected.lowercased()
    }
}
