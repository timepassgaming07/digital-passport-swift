import Foundation

enum DocumentConsentMode: String, Codable, CaseIterable, Identifiable {
    case verifyOnly = "verify_only"
    case shareFiles = "share_files"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .verifyOnly: return "Verify Only"
        case .shareFiles: return "Share Files"
        }
    }

    var detail: String {
        switch self {
        case .verifyOnly:
            return "Share only cryptographic proof + verification status"
        case .shareFiles:
            return "Share selected document payloads with proof"
        }
    }
}

enum DocumentItemStatus: String, Codable {
    case verified
    case missing
    case failed
}

struct RequestedDocumentItem: Identifiable, Codable, Hashable {
    let id: String
    let type: CredentialType
    let title: String
    let required: Bool
}

struct SharedDocumentItem: Identifiable, Codable, Hashable {
    let id: String                      // mirrors request item id
    let type: CredentialType
    let title: String
    let status: DocumentItemStatus
    let credentialId: String?
    let issuerDid: String?
    let subjectDid: String?
    let issuedAt: Int?
    let expiresAt: Int?
    let credentialHash: String?
    let hasSignature: Bool
    let proofHash: String?
    let sharedPayload: String?
    let note: String?
}

struct DocumentRequestPayload: Codable, Hashable {
    let v: Int
    let t: String
    let requestId: String
    let requesterDid: String
    let requesterName: String
    let createdAt: Int
    let expiresAt: Int
    let nonce: String
    let requestLocation: ProductLocation?
    let items: [RequestedDocumentItem]

    var isExpired: Bool {
        Date().timeIntervalSince1970 > Double(expiresAt)
    }
}

struct DocumentResponsePayload: Codable, Hashable {
    let v: Int
    let t: String
    let requestId: String
    let requesterDid: String
    let responderDid: String
    let responderName: String
    let consentMode: DocumentConsentMode
    let nonce: String
    let respondedAt: Int
    let responseLocation: ProductLocation?
    let items: [SharedDocumentItem]
    let signerPublicKey: String
    let signature: String
}

struct DocumentConfirmationItem: Identifiable, Hashable {
    let id: String
    let title: String
    let status: DocumentItemStatus
    let note: String
}

struct DocumentRequestConfirmation: Hashable {
    let requestId: String
    let consentMode: DocumentConsentMode
    let signatureValid: Bool
    let nonceValid: Bool
    let withinExpiry: Bool
    let responderDid: String
    let respondedAt: Date
    let responseLocation: ProductLocation?
    let items: [DocumentConfirmationItem]
    let summary: String

    var allVerified: Bool {
        signatureValid && nonceValid && withinExpiry && items.allSatisfy { $0.status == .verified }
    }
}
