import SwiftUI
import Foundation
enum PostVerificationStatus: String, Codable {
    case verifiedAuthor, unverifiedAuthor, disputed, synthetic, unknown
}
enum FraudSeverity: String, Codable {
    case low, medium, high, critical
    var color: SwiftUI.Color {
        switch self {
        case .low:      return .init(hex:"FFD60A")
        case .medium:   return .init(hex:"F97316")
        case .high:     return .init(hex:"FF3355")
        case .critical: return .init(hex:"FF0055")
        }
    }
}
enum FraudSignalId: String, Codable {
    case unknownIssuer, revokedCredential, suspiciousInstitution
    case invalidSignature, unverifiedAuthor, noInstitution
    case unverifiedClaims, noSource, syntheticContent, rapidPosting, credentialMismatch
}
struct FraudSignal: Identifiable, Codable {
    let id: FraudSignalId; let label: String
    let severity: FraudSeverity; let detail: String?; let remediation: String?
}
struct FraudAnalysis: Codable {
    let trustState: TrustState; let signals: [FraudSignal]
    let riskScore: Int; let analysedAt: Date
}
struct PostAuthor: Codable {
    let did: String; let displayName: String; let handle: String
    let avatarEmoji: String; let institution: String?
    let trustState: TrustState; let isVerified: Bool
}
struct Post: Identifiable, Codable {
    let id: String; let content: String; let author: PostAuthor
    let sourceUrl: String?; let sourceName: String?
    let publishedAt: Date; let verificationStatus: PostVerificationStatus
    let trustState: TrustState; let claimCount: Int
    let verifiedClaimCount: Int; let tags: [String]
    var fraudAnalysis: FraudAnalysis?
    var claimRatio: Double {
        claimCount > 0 ? Double(verifiedClaimCount) / Double(claimCount) : 0
    }
}
