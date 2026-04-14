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

enum PaperlessDocumentType: String, Codable, CaseIterable {
    case medicalReport = "medical_report"
    case certificate = "certificate"
    case employeeId = "employee_id"
    case legalDocument = "legal_document"

    var label: String {
        switch self {
        case .medicalReport: return "Medical Report"
        case .certificate: return "Certificate"
        case .employeeId: return "Employee ID"
        case .legalDocument: return "Legal Document"
        }
    }

    var icon: String {
        switch self {
        case .medicalReport: return "cross.case.fill"
        case .certificate: return "graduationcap.fill"
        case .employeeId: return "person.text.rectangle.fill"
        case .legalDocument: return "doc.text.fill"
        }
    }

    // Issuer role is locked by document class to prevent free-text role spoofing.
    var verifiedIssuerRole: String {
        switch self {
        case .medicalReport: return "Verified Medical Issuer"
        case .certificate: return "Verified Certification Issuer"
        case .employeeId: return "Verified Employment Issuer"
        case .legalDocument: return "Verified Legal Issuer"
        }
    }

    // Issuer identity is locked by document class to prevent name/DID spoofing.
    var verifiedIssuerProfile: VerificationIssuerProfile {
        switch self {
        case .medicalReport:
            return VerificationIssuerProfile(
                id: "issuer_medical_citycare_hospital",
                did: "did:sov:CITYCARE-HOSP-0xM3D1C4",
                displayName: "Dr. Asha Verma",
                handle: "@dr.asha.citycare",
                avatarEmoji: "🩺",
                institution: "CityCare Hospital",
                roleLabel: verifiedIssuerRole,
                trustState: .verified
            )
        case .certificate:
            return VerificationIssuerProfile(
                id: "issuer_certificate_iitb_registrar",
                did: "did:sov:IIT-Bombay-0xA1B2C3",
                displayName: "IIT Bombay Registrar",
                handle: "@iitb.registrar",
                avatarEmoji: "🎓",
                institution: "Indian Institute of Technology Bombay",
                roleLabel: verifiedIssuerRole,
                trustState: .verified
            )
        case .employeeId:
            return VerificationIssuerProfile(
                id: "issuer_employment_aws_hr",
                did: "did:sov:Amazon-AWS-0xG7H8I9",
                displayName: "AWS HR Verification",
                handle: "@aws.hr.verify",
                avatarEmoji: "🏢",
                institution: "Amazon Web Services",
                roleLabel: verifiedIssuerRole,
                trustState: .trusted
            )
        case .legalDocument:
            return VerificationIssuerProfile(
                id: "issuer_legal_sebi_registry",
                did: "did:sov:SEBI-GOV-0xS4T5U6",
                displayName: "SEBI Legal Registry",
                handle: "@sebi.legal.registry",
                avatarEmoji: "⚖️",
                institution: "Securities and Exchange Board of India",
                roleLabel: verifiedIssuerRole,
                trustState: .trusted
            )
        }
    }

    // Simple working permission map: one DID can hold multiple issuer permissions.
    private static var walletIssuerPermissions: [String: Set<PaperlessDocumentType>] {
        [
            Identity.mock.did.lowercased(): [.medicalReport, .employeeId, .certificate],
            "did:sov:CITYCARE-HOSP-0xM3D1C4".lowercased(): [.medicalReport],
            "did:sov:IIT-Bombay-0xA1B2C3".lowercased(): [.certificate],
            "did:sov:Amazon-AWS-0xG7H8I9".lowercased(): [.employeeId],
            "did:sov:SEBI-GOV-0xS4T5U6".lowercased(): [.legalDocument]
        ]
    }

    var authorizedIssuerDIDs: Set<String> {
        Set(Self.walletIssuerPermissions.compactMap { did, permissions in
            permissions.contains(self) ? did : nil
        })
    }

    func isAuthorizedIssuerDid(_ did: String) -> Bool {
        authorizedIssuerDIDs.contains(did.lowercased())
    }

    static func authorizedDocumentTypes(for did: String) -> [PaperlessDocumentType] {
        let permissions = walletIssuerPermissions[did.lowercased()] ?? []
        return allCases.filter { permissions.contains($0) }
    }
}

struct VerificationIssuerProfile: Identifiable, Codable, Hashable {
    let id: String
    let did: String
    let displayName: String
    let handle: String
    let avatarEmoji: String
    let institution: String
    let roleLabel: String
    let trustState: TrustState

    var asAuthor: PostAuthor {
        PostAuthor(
            did: did,
            displayName: displayName,
            handle: handle,
            avatarEmoji: avatarEmoji,
            institution: institution,
            trustState: trustState,
            isVerified: true
        )
    }
}

struct DocumentProofMetadata: Codable, Hashable {
    let recordId: String
    let documentType: PaperlessDocumentType
    let title: String
    let subjectName: String
    let subjectDid: String
    let issuerDid: String
    let issuerAccountId: String
    let issuerRole: String
    let verificationCode: String
    let payloadHash: String
    let issuerSignatureHash: String
    let issuedAt: Date
    let expiresAt: Date?
    let verificationCount: Int
    let mlRiskScore: Int
    let mlWarning: String?

    var verificationURL: String {
        "https://sovereigntrust.app/verify/\(verificationCode)"
    }
}

struct Post: Identifiable, Codable {
    let id: String; let content: String; let author: PostAuthor
    let sourceUrl: String?; let sourceName: String?
    let publishedAt: Date; let verificationStatus: PostVerificationStatus
    let trustState: TrustState; let claimCount: Int
    let verifiedClaimCount: Int; let tags: [String]
    let documentProof: DocumentProofMetadata?
    var fraudAnalysis: FraudAnalysis?
    var claimRatio: Double {
        claimCount > 0 ? Double(verifiedClaimCount) / Double(claimCount) : 0
    }
}
