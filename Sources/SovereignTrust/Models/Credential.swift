import Foundation
enum CredentialType: String, Codable, CaseIterable {
    case education, identity, professional, membership, product, document
    var icon: String {
        switch self {
        case .education:    return "graduationcap.fill"
        case .identity:     return "person.crop.rectangle.fill"
        case .professional: return "briefcase.fill"
        case .membership:   return "person.2.fill"
        case .product:      return "shippingbox.fill"
        case .document:     return "doc.text.fill"
        }
    }
    var label: String { rawValue.capitalized }
}
enum CredentialStatus: String, Codable {
    case active, revoked, expired, suspended
}
struct Credential: Identifiable, Codable, Equatable {
    let id: String
    let type: CredentialType
    let title: String
    let description: String?
    let issuerDid: String
    let subjectDid: String
    let issuedAt: Date
    let expiresAt: Date?
    let status: CredentialStatus
    let trustState: TrustState
    let hash: String
    let signature: String?
    let isVerified: Bool
    let rawJson: String?
    var isExpired: Bool { expiresAt?.isExpired ?? false }
}
struct Issuer: Identifiable, Codable, Equatable {
    let id: String; let did: String; let name: String; let shortName: String
    let logoEmoji: String; let category: String
    let trustState: TrustState; let isVerified: Bool; let country: String
}
struct CredentialWithIssuer: Identifiable {
    var id: String { credential.id }
    let credential: Credential; let issuer: Issuer
}
