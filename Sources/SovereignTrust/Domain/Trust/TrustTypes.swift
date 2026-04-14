import Foundation

// MARK: – Trust Score Input Features

/// All observable signals fed into the TrustEngine for anomaly detection.
struct TrustInput {
    // Scan behaviour
    let scanTimestamp: Date
    let recentScanTimestamps: [Date]          // recent scans within window

    // Credential signals
    let credentialId: String?
    let credentialReuseCount: Int              // times this credential has been scanned
    let credentialAge: TimeInterval            // seconds since issuance
    let credentialStatus: CredentialStatus?
    let isExpired: Bool

    // Issuer signals
    let issuerDid: String?
    let issuerTrustState: TrustState?
    let issuerIsVerified: Bool
    let issuerInRegistry: Bool

    // Verification history
    let recentPassCount: Int                   // recent verifications that passed
    let recentFailCount: Int                   // recent verifications that failed
    let totalVerifications: Int

    // Subject context
    let subjectType: VerificationSubjectType
    let payloadSizeBytes: Int
    let hasSignature: Bool
    let hasValidStructure: Bool
}

// MARK: – Trust Score Output

/// The engine's final assessment — deterministic, <1ms.
struct TrustScore: Codable {
    let score: Int                            // 0–100
    let riskLevel: RiskLevel
    let reasons: [TrustReason]
    let computedAt: Date

    var trustState: TrustState {
        switch riskLevel {
        case .low:    return .verified
        case .medium: return .trusted
        case .high:   return .suspicious
        }
    }
}

enum RiskLevel: String, Codable {
    case low, medium, high

    var label: String {
        switch self {
        case .low:    return "Safe"
        case .medium: return "Caution"
        case .high:   return "Risky"
        }
    }

    var color: String {
        switch self {
        case .low:    return "00FF88"   // green
        case .medium: return "FFD60A"   // yellow
        case .high:   return "FF3355"   // red
        }
    }
}

struct TrustReason: Identifiable, Codable {
    let id: String
    let signal: String                        // human-readable
    let weight: Double                        // contribution to score
    let severity: ReasonSeverity

    init(signal: String, weight: Double, severity: ReasonSeverity) {
        self.id = UUID().uuidString
        self.signal = signal
        self.weight = weight
        self.severity = severity
    }
}

enum ReasonSeverity: String, Codable {
    case positive, neutral, warning, critical
}

// MARK: – Feature Vector (internal representation for engine)

/// Normalised feature vector consumed by the scoring pipeline.
/// Each feature is 0.0–1.0 (higher = more suspicious).
struct FeatureVector {
    var scanFrequencyAnomaly: Double = 0      // z-score normalised
    var timingAnomaly: Double = 0             // unusual hour
    var credentialReuseAnomaly: Double = 0    // excessive re-scans
    var issuerTrustDeficit: Double = 0        // unverified / unknown issuer
    var verificationFailureRate: Double = 0   // fail ratio
    var structuralAnomaly: Double = 0         // missing sig / bad format
    var expirationRisk: Double = 0            // expired or near-expiry
    var ageAnomaly: Double = 0                // freshly issued or extremely old
}
