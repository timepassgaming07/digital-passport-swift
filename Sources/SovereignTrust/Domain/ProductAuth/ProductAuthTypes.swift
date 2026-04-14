import Foundation
import CoreLocation

// MARK: – Product Authentication Types

enum ProductRiskLevel: String, Codable, Hashable {
    case low
    case medium
    case high
    case critical

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

struct ProductAuthenticitySignal: Identifiable, Codable, Hashable {
    let id: String
    let key: String
    let value: Double
    let weight: Double
    let contribution: Double
    let detail: String
}

struct ProductAuthenticityAssessment: Codable, Hashable {
    let modelVersion: String
    let evaluatedAt: Date
    let productId: String
    let score: Int                       // 0-100 (higher is safer)
    let confidence: Int                  // 0-100
    let riskLevel: ProductRiskLevel
    let scanLocation: ProductLocation?
    let reasons: [String]
    let signals: [ProductAuthenticitySignal]
}

/// A product registered by a manufacturer and ready for consumer verification.
struct RegisteredProduct: Identifiable, Codable, Hashable {
    let id: String
    let product: Product
    let manufacturerVerifiedAt: Date
    let manufacturerSignature: String          // cryptographic signature
    let qrHash: String                         // SHA-256 of the QR payload
    let manufacturerLocation: ProductLocation? // real GPS where manufacturer first scanned
    let manufacturerDid: String?               // DID of the verifying manufacturer
    var latestAssessment: ProductAuthenticityAssessment?
    var isVerified: Bool { true }
}

/// Ownership claim — a user who has claimed a product via OTP.
struct ProductOwnership: Identifiable, Codable {
    let id: String
    let productId: String
    let ownerDid: String
    let claimedAt: Date
    let claimLocation: ProductLocation?
    let billReference: String?                 // bill/receipt identifier
    let isFirstOwner: Bool
}

/// Location captured at scan time — real GPS, no simulation.
struct ProductLocation: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let city: String
    let country: String
    let formattedAddress: String
}

/// OTP for ownership claim — generated on-device with cryptographic randomness.
struct ProductOTP: Codable {
    let code: String                           // 6-digit OTP
    let productId: String
    let generatedAt: Date
    let expiresAt: Date
    var isExpired: Bool { Date() > expiresAt }

    static func generate(for productId: String) -> ProductOTP {
        // Use SecRandomCopyBytes for real cryptographic randomness
        var randomBytes = [UInt8](repeating: 0, count: 4)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let value = randomBytes.withUnsafeBytes { $0.load(as: UInt32.self) } % 900000 + 100000
        let code = String(format: "%06d", value)
        return ProductOTP(
            code: code, productId: productId,
            generatedAt: Date(),
            expiresAt: Date().addingTimeInterval(300) // 5 min validity
        )
    }
}

/// Result of scanning a product QR.
enum ProductVerificationStatus {
    case authentic(RegisteredProduct, ProductAuthenticityAssessment)
    case counterfeit(reason: String, ProductAuthenticityAssessment?)
    case unregistered(ProductAuthenticityAssessment?)
    case alreadyOwned(ProductOwnership, ProductAuthenticityAssessment?)
}

/// Who performed the scan.
enum ScanActor: String, Codable {
    case manufacturer
    case consumer
}

/// Scan event for audit trail — tracks who scanned, from where, and when.
struct ProductScanEvent: Identifiable, Codable {
    let id: String
    let productId: String
    let scannedAt: Date
    let location: ProductLocation?             // real GPS location
    let result: String                         // "authentic" | "counterfeit" | "unregistered"
    let actor: ScanActor                       // manufacturer or consumer
    let scannerDid: String?                    // DID of the scanner
    let authenticityScore: Int?
    let riskLevel: ProductRiskLevel?
    let dominantSignal: String?
}
