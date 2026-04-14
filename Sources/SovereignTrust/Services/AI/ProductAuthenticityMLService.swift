import Foundation
import CryptoKit
import CoreLocation

// MARK: – Product Authenticity ML Service
// On-device risk scoring from real QR payload, real scan history, and real GPS context.

actor ProductAuthenticityMLService {
    static let shared = ProductAuthenticityMLService()
    private init() {}

    private let modelVersion = "qr-auth-v1.0.0"

    func evaluate(
        rawPayload: String,
        productId: String,
        serial: String?,
        registered: RegisteredProduct?,
        scanLocation: ProductLocation?,
        history: [ProductScanEvent]
    ) -> ProductAuthenticityAssessment {
        let now = Date()
        var riskScore: Double = 8
        var signals: [ProductAuthenticitySignal] = []

        func addSignal(key: String, value: Double, weight: Double, detail: String) {
            let boundedValue = max(0, min(1, value))
            let contribution = boundedValue * weight
            riskScore += contribution
            signals.append(ProductAuthenticitySignal(
                id: UUID().uuidString,
                key: key,
                value: boundedValue,
                weight: weight,
                contribution: contribution,
                detail: detail
            ))
        }

        let payloadBytes = rawPayload.utf8.count
        let lengthRisk: Double
        switch payloadBytes {
        case ..<40: lengthRisk = 0.85
        case 40..<80: lengthRisk = 0.45
        case 80...1800: lengthRisk = 0.04
        default: lengthRisk = 0.35
        }
        addSignal(
            key: "payload_length",
            value: lengthRisk,
            weight: 14,
            detail: "Payload size is \(payloadBytes) bytes"
        )

        let entropy = Self.shannonEntropy(rawPayload)
        addSignal(
            key: "payload_entropy",
            value: Self.entropyRisk(entropy),
            weight: 16,
            detail: "Shannon entropy \(String(format: "%.2f", entropy))"
        )

        let parsed = QRParserService.parse(rawPayload)
        addSignal(
            key: "payload_structure",
            value: parsed.type == .unknown ? 0.55 : 0.05,
            weight: 12,
            detail: parsed.type == .unknown ? "Non-standard QR structure" : "Structured QR payload"
        )

        addSignal(
            key: "timestamp_freshness",
            value: Self.timestampRisk(parsed.payload?.ts),
            weight: 10,
            detail: "QR timestamp freshness check"
        )

        let dynamic = Self.dynamicPayloadIntegrity(parsed.payload)
        addSignal(
            key: "dynamic_qr_integrity",
            value: dynamic.risk,
            weight: 24,
            detail: dynamic.detail
        )

        if let registered {
            let payloadFingerprint = Self.canonicalProductFingerprint(
                id: parsed.payload?.id ?? productId,
                serial: parsed.payload?.serial ?? serial ?? "",
                manufacturerDid: parsed.payload?.did ?? registered.product.manufacturerDid,
                brand: parsed.payload?.brand ?? registered.product.brand,
                title: parsed.payload?.title ?? registered.product.name
            )
            let expectedFingerprint = Self.canonicalProductFingerprint(
                id: registered.product.id,
                serial: registered.product.serialNumber,
                manufacturerDid: registered.product.manufacturerDid,
                brand: registered.product.brand,
                title: registered.product.name
            )
            let legacyHash = Self.sha256Hex(registered.product.id)
            let hashMismatchRisk = (registered.qrHash == payloadFingerprint ||
                                    registered.qrHash == expectedFingerprint ||
                                    registered.qrHash == legacyHash) ? 0.0 : 1.0
            addSignal(
                key: "registry_hash_match",
                value: hashMismatchRisk,
                weight: 36,
                detail: hashMismatchRisk == 0 ? "Registry QR hash matched" : "Registry QR hash mismatch"
            )

            if let serial, !serial.isEmpty {
                let serialMismatchRisk = serial.caseInsensitiveCompare(registered.product.serialNumber) == .orderedSame ? 0.0 : 1.0
                addSignal(
                    key: "serial_consistency",
                    value: serialMismatchRisk,
                    weight: 42,
                    detail: serialMismatchRisk == 0 ? "Serial number matched" : "Serial number mismatch"
                )
            } else {
                addSignal(
                    key: "serial_presence",
                    value: 0.30,
                    weight: 8,
                    detail: "QR payload missing serial number"
                )
            }

            if let payloadDid = parsed.payload?.did.lowercased() {
                let didMismatchRisk = payloadDid == registered.product.manufacturerDid.lowercased() ? 0.0 : 0.7
                addSignal(
                    key: "manufacturer_did_match",
                    value: didMismatchRisk,
                    weight: 22,
                    detail: didMismatchRisk == 0 ? "Manufacturer DID matched" : "Manufacturer DID mismatch"
                )
            } else {
                addSignal(
                    key: "manufacturer_did_presence",
                    value: 0.25,
                    weight: 6,
                    detail: "QR payload missing manufacturer DID"
                )
            }

            if let origin = registered.manufacturerLocation, let scanLocation {
                let distanceKm = Self.distanceKm(from: origin, to: scanLocation)
                addSignal(
                    key: "geo_distance_from_origin",
                    value: Self.geoDistanceRisk(distanceKm: distanceKm),
                    weight: 18,
                    detail: "Distance from manufacturer origin: \(Int(distanceKm)) km"
                )
            } else {
                addSignal(
                    key: "geo_distance_from_origin",
                    value: 0.20,
                    weight: 5,
                    detail: "Insufficient location context to compute geo-distance"
                )
            }
        } else {
            addSignal(
                key: "registry_presence",
                value: 1.0,
                weight: 54,
                detail: "Product ID not found in registry"
            )
        }

        let recentHourScans = history.filter { $0.scannedAt >= now.addingTimeInterval(-3600) }.count
        addSignal(
            key: "scan_velocity",
            value: Self.scanVelocityRisk(scanCountInHour: recentHourScans),
            weight: 22,
            detail: "Recent scans in 1h: \(recentHourScans)"
        )

        addSignal(
            key: "geo_jump_pattern",
            value: Self.geoJumpRisk(history: history, scanLocation: scanLocation, now: now),
            weight: 20,
            detail: "Geo-jump check across recent scan locations"
        )

        addSignal(
            key: "unknown_scanner_ratio",
            value: Self.unknownScannerRisk(history: history),
            weight: 10,
            detail: "Ratio of scans without scanner DID"
        )

        let boundedRisk = max(0, min(99, riskScore))
        let score = Int(max(1, min(99, round(100 - boundedRisk))))
        let confidence = Self.confidence(
            hasRegisteredProduct: registered != nil,
            hasScanLocation: scanLocation != nil,
            historyCount: history.count,
            signalCount: signals.count
        )
        let sorted = signals.sorted { $0.contribution > $1.contribution }

        return ProductAuthenticityAssessment(
            modelVersion: modelVersion,
            evaluatedAt: now,
            productId: productId,
            score: score,
            confidence: confidence,
            riskLevel: Self.riskLevel(for: score),
            scanLocation: scanLocation,
            reasons: sorted.prefix(3).map(\.detail),
            signals: sorted
        )
    }

    private static func riskLevel(for score: Int) -> ProductRiskLevel {
        switch score {
        case 80...: return .low
        case 60..<80: return .medium
        case 40..<60: return .high
        default: return .critical
        }
    }

    private static func confidence(
        hasRegisteredProduct: Bool,
        hasScanLocation: Bool,
        historyCount: Int,
        signalCount: Int
    ) -> Int {
        var value = 50
        value += min(signalCount * 3, 24)
        value += hasRegisteredProduct ? 12 : 0
        value += hasScanLocation ? 10 : 0
        value += min(historyCount * 2, 16)
        return max(40, min(95, value))
    }

    private static func sha256Hex(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func shannonEntropy(_ text: String) -> Double {
        let bytes = Array(text.utf8)
        guard !bytes.isEmpty else { return 0 }
        var counts: [UInt8: Int] = [:]
        for byte in bytes {
            counts[byte, default: 0] += 1
        }
        let total = Double(bytes.count)
        return counts.values.reduce(0) { partial, count in
            let p = Double(count) / total
            return partial - (p * log2(p))
        }
    }

    private static func entropyRisk(_ entropy: Double) -> Double {
        if entropy < 2.4 {
            return min(1, (2.4 - entropy) / 2.4)
        }
        if entropy > 5.6 {
            return min(1, (entropy - 5.6) / 2.5)
        }
        return 0.04
    }

    private static func dynamicPayloadIntegrity(_ payload: QRPayload?) -> (risk: Double, detail: String) {
        guard let payload else {
            return (0.80, "QR payload could not be parsed")
        }
        guard let nonce = payload.nonce, !nonce.isEmpty else {
            return (0.90, "Missing dynamic nonce")
        }

        let expected = dynamicPayloadHash(
            id: payload.id,
            serial: payload.serial ?? "",
            did: payload.did,
            nonce: nonce,
            ts: payload.ts
        )
        if expected.lowercased() == payload.hash.lowercased() {
            return (0.05, "Dynamic QR integrity matched")
        }
        return (1.00, "Dynamic QR hash mismatch")
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

    private static func timestampRisk(_ ts: String?) -> Double {
        guard let ts, !ts.isEmpty else { return 0.35 }

        let now = Date().timeIntervalSince1970
        let oneWeek = 3600.0 * 24.0 * 7.0
        let ninetyDays = 3600.0 * 24.0 * 90.0

        if let unix = Double(ts) {
            let age = abs(now - unix)
            switch age {
            case ..<oneWeek: return 0.05
            case ..<ninetyDays: return 0.20
            default: return 0.60
            }
        }

        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: ts) {
            let age = abs(Date().timeIntervalSince(date))
            switch age {
            case ..<oneWeek: return 0.05
            case ..<ninetyDays: return 0.20
            default: return 0.60
            }
        }

        return 0.45
    }

    private static func distanceKm(from: ProductLocation, to: ProductLocation) -> Double {
        let source = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let destination = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return source.distance(from: destination) / 1000
    }

    private static func geoDistanceRisk(distanceKm: Double) -> Double {
        switch distanceKm {
        case ..<80: return 0.02
        case ..<800: return 0.16
        case ..<2500: return 0.35
        case ..<7000: return 0.55
        default: return 0.72
        }
    }

    private static func scanVelocityRisk(scanCountInHour: Int) -> Double {
        switch scanCountInHour {
        case 0...1: return 0.02
        case 2...3: return 0.25
        case 4...6: return 0.55
        default: return 0.90
        }
    }

    private static func geoJumpRisk(
        history: [ProductScanEvent],
        scanLocation: ProductLocation?,
        now: Date
    ) -> Double {
        guard let scanLocation else { return 0.20 }

        let recent = history.filter { $0.scannedAt >= now.addingTimeInterval(-3600 * 12) }
        let recentCountries = Set(recent.compactMap { $0.location?.country.lowercased() })

        if recentCountries.isEmpty {
            return 0.05
        }

        if recentCountries.contains(scanLocation.country.lowercased()) {
            return 0.08
        }

        let extra = min(0.40, Double(recentCountries.count) * 0.10)
        return 0.35 + extra
    }

    private static func unknownScannerRisk(history: [ProductScanEvent]) -> Double {
        guard !history.isEmpty else { return 0.15 }
        let unknown = history.filter { ($0.scannerDid ?? "").isEmpty }.count
        let ratio = Double(unknown) / Double(history.count)
        return max(0, min(1, ratio))
    }
}
