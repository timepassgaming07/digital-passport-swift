import SwiftUI
import Foundation
enum VerificationSubjectType: String, Codable {
    case credential, product, document, login, post, did, unknown
    var icon: String {
        switch self {
        case .credential: return "checkmark.seal.fill"
        case .product:    return "shippingbox.fill"
        case .document:   return "doc.text.fill"
        case .login:      return "person.badge.key.fill"
        case .post:       return "newspaper.fill"
        case .did:        return "link"
        case .unknown:    return "questionmark.circle.fill"
        }
    }
    var label: String { rawValue.capitalized }
}
enum CheckOutcome: String, Codable {
    case pass, fail, warn, unknown
    var color: SwiftUI.Color {
        switch self {
        case .pass:    return .init(hex:"00FF88")
        case .fail:    return .init(hex:"FF3355")
        case .warn:    return .init(hex:"FFD60A")
        case .unknown: return .init(hex:"8E8E93")
        }
    }
    var icon: String {
        switch self {
        case .pass:    return "checkmark.circle.fill"
        case .fail:    return "xmark.circle.fill"
        case .warn:    return "exclamationmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}
struct VerificationCheck: Identifiable, Codable {
    let id: String; let label: String; let outcome: CheckOutcome; let detail: String?
}
struct VerificationResult: Identifiable, Codable {
    let id: String; let subjectId: String; let subjectType: VerificationSubjectType
    let trustState: TrustState; let checks: [VerificationCheck]
    let summary: String; let verifiedAt: Date; let durationMs: Int
    var passCount: Int { checks.filter{$0.outcome == .pass}.count }
    var failCount: Int { checks.filter{$0.outcome == .fail}.count }
    var warnCount: Int { checks.filter{$0.outcome == .warn}.count }
}
