import Foundation
import CryptoKit
import UniformTypeIdentifiers

// MARK: – Document Exchange Service
// Requester creates request QR -> holder scans, consents, signs response -> requester verifies batch.

actor DocumentExchangeService {
    static let shared = DocumentExchangeService()
    private init() {}

    func createRequest(
        requester: Identity,
        requestedTypes: [CredentialType],
        location: ProductLocation?,
        validityMinutes: Int = 10
    ) -> (payload: DocumentRequestPayload, qrPayload: String) {
        let uniqueTypes = Array(Set(requestedTypes)).sorted { $0.rawValue < $1.rawValue }
        let now = Date()

        let items = uniqueTypes.map {
            RequestedDocumentItem(
                id: UUID().uuidString,
                type: $0,
                title: $0.label,
                required: true
            )
        }

        let request = DocumentRequestPayload(
            v: 1,
            t: "doc_request",
            requestId: UUID().uuidString,
            requesterDid: requester.did,
            requesterName: requester.displayName,
            createdAt: Int(now.timeIntervalSince1970),
            expiresAt: Int(now.addingTimeInterval(Double(validityMinutes) * 60).timeIntervalSince1970),
            nonce: Self.randomNonce(),
            requestLocation: location,
            items: items
        )

        return (request, (try? Self.encodeCanonical(request)) ?? "")
    }

    func parseRequest(raw: String) -> DocumentRequestPayload? {
        guard let data = raw.data(using: .utf8),
              let request = try? JSONDecoder().decode(DocumentRequestPayload.self, from: data),
              request.t == "doc_request" else {
            return nil
        }
        return request
    }

    func parseResponse(raw: String) -> DocumentResponsePayload? {
        guard let data = raw.data(using: .utf8),
              let response = try? JSONDecoder().decode(DocumentResponsePayload.self, from: data),
              response.t == "doc_response" else {
            return nil
        }
        return response
    }

    func buildResponse(
        request: DocumentRequestPayload,
        holder: Identity,
        holderCredentials: [Credential],
        consentMode: DocumentConsentMode,
        location: ProductLocation?
    ) async throws -> (payload: DocumentResponsePayload, qrPayload: String) {
        let now = Date()
        let grouped = Dictionary(grouping: holderCredentials) { $0.type }

        let items = request.items.map { item in
            let best = grouped[item.type]?
                .sorted { $0.issuedAt > $1.issuedAt }
                .first

            guard let credential = best else {
                return SharedDocumentItem(
                    id: item.id,
                    type: item.type,
                    title: item.title,
                    status: .missing,
                    credentialId: nil,
                    issuerDid: nil,
                    subjectDid: nil,
                    issuedAt: nil,
                    expiresAt: nil,
                    credentialHash: nil,
                    hasSignature: false,
                    proofHash: nil,
                    sharedPayload: nil,
                    note: "No matching credential found"
                )
            }

            if credential.status != .active || credential.isExpired {
                return SharedDocumentItem(
                    id: item.id,
                    type: item.type,
                    title: credential.title,
                    status: .failed,
                    credentialId: credential.id,
                    issuerDid: credential.issuerDid,
                    subjectDid: credential.subjectDid,
                    issuedAt: Int(credential.issuedAt.timeIntervalSince1970),
                    expiresAt: credential.expiresAt.map { Int($0.timeIntervalSince1970) },
                    credentialHash: credential.hash,
                    hasSignature: credential.signature != nil,
                    proofHash: nil,
                    sharedPayload: nil,
                    note: "Credential is not active or already expired"
                )
            }

            let payloadToShare: String? = {
                if consentMode == .shareFiles {
                    return credential.rawJson ?? Self.fallbackCredentialPayload(credential)
                }
                return nil
            }()

            return Self.verifiedItem(
                requestItemId: item.id,
                credential: credential,
                sharedPayload: payloadToShare
            )
        }

        let publicKey = try await SecureEnclaveService.shared.publicKeyData().base64EncodedString()

        let unsigned = UnsignedResponsePayload(
            v: 1,
            t: "doc_response",
            requestId: request.requestId,
            requesterDid: request.requesterDid,
            responderDid: holder.did,
            responderName: holder.displayName,
            consentMode: consentMode,
            nonce: request.nonce,
            respondedAt: Int(now.timeIntervalSince1970),
            responseLocation: location,
            items: items,
            signerPublicKey: publicKey
        )

        let unsignedData = try Self.encodeCanonicalData(unsigned)
        let signature = try await SecureEnclaveService.shared.sign(payload: unsignedData).base64EncodedString()

        let response = DocumentResponsePayload(
            v: unsigned.v,
            t: unsigned.t,
            requestId: unsigned.requestId,
            requesterDid: unsigned.requesterDid,
            responderDid: unsigned.responderDid,
            responderName: unsigned.responderName,
            consentMode: unsigned.consentMode,
            nonce: unsigned.nonce,
            respondedAt: unsigned.respondedAt,
            responseLocation: unsigned.responseLocation,
            items: unsigned.items,
            signerPublicKey: unsigned.signerPublicKey,
            signature: signature
        )

        return (response, try Self.encodeCanonical(response))
    }

    func confirmResponse(
        request: DocumentRequestPayload,
        rawResponse: String
    ) -> DocumentRequestConfirmation? {
        guard let response = parseResponse(raw: rawResponse) else { return nil }

        let unsigned = UnsignedResponsePayload(
            v: response.v,
            t: response.t,
            requestId: response.requestId,
            requesterDid: response.requesterDid,
            responderDid: response.responderDid,
            responderName: response.responderName,
            consentMode: response.consentMode,
            nonce: response.nonce,
            respondedAt: response.respondedAt,
            responseLocation: response.responseLocation,
            items: response.items,
            signerPublicKey: response.signerPublicKey
        )

        let unsignedData = (try? Self.encodeCanonicalData(unsigned)) ?? Data()
        let signatureValid = Self.verifySignature(
            message: unsignedData,
            signatureBase64: response.signature,
            publicKeyBase64: response.signerPublicKey
        )

        let nonceValid =
            response.requestId == request.requestId &&
            response.requesterDid == request.requesterDid &&
            response.nonce == request.nonce

        let withinExpiry = response.respondedAt <= request.expiresAt

        let items = request.items.map { requested in
            guard let provided = response.items.first(where: { $0.id == requested.id }) else {
                return DocumentConfirmationItem(
                    id: requested.id,
                    title: requested.title,
                    status: .missing,
                    note: "No response for this requested document"
                )
            }

            var status = provided.status
            var notes: [String] = []

            if provided.type != requested.type {
                status = .failed
                notes.append("Type mismatch")
            }

            if status == .verified {
                if !Self.verifyProofHash(provided) {
                    status = .failed
                    notes.append("Proof hash mismatch")
                }
                if response.consentMode == .shareFiles && (provided.sharedPayload ?? "").isEmpty {
                    status = .failed
                    notes.append("Expected shared document payload")
                }
                if let exp = provided.expiresAt,
                   Double(exp) < Date().timeIntervalSince1970 {
                    status = .failed
                    notes.append("Document proof expired")
                }
                if provided.hasSignature == false {
                    notes.append("Credential has no embedded signature")
                }
            }

            if !signatureValid {
                status = .failed
                notes.append("Invalid response signature")
            }
            if !nonceValid {
                status = .failed
                notes.append("Request-response nonce mismatch")
            }
            if !withinExpiry {
                status = .failed
                notes.append("Response arrived after request expiry")
            }

            return DocumentConfirmationItem(
                id: requested.id,
                title: requested.title,
                status: status,
                note: notes.isEmpty ? (provided.note ?? "Verified") : notes.joined(separator: " • ")
            )
        }

        let ok = items.filter { $0.status == .verified }.count
        let fail = items.filter { $0.status == .failed }.count
        let miss = items.filter { $0.status == .missing }.count

        let summary = "\(ok) verified, \(fail) failed, \(miss) missing"

        return DocumentRequestConfirmation(
            requestId: request.requestId,
            consentMode: response.consentMode,
            signatureValid: signatureValid,
            nonceValid: nonceValid,
            withinExpiry: withinExpiry,
            responderDid: response.responderDid,
            respondedAt: Date(timeIntervalSince1970: TimeInterval(response.respondedAt)),
            responseLocation: response.responseLocation,
            items: items,
            summary: summary
        )
    }

    private static func verifiedItem(
        requestItemId: String,
        credential: Credential,
        sharedPayload: String?
    ) -> SharedDocumentItem {
        let issuedAt = Int(credential.issuedAt.timeIntervalSince1970)
        let expiresAt = credential.expiresAt.map { Int($0.timeIntervalSince1970) }

        let unhashed = SharedDocumentItem(
            id: requestItemId,
            type: credential.type,
            title: credential.title,
            status: .verified,
            credentialId: credential.id,
            issuerDid: credential.issuerDid,
            subjectDid: credential.subjectDid,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            credentialHash: credential.hash,
            hasSignature: credential.signature != nil,
            proofHash: nil,
            sharedPayload: sharedPayload,
            note: nil
        )

        return SharedDocumentItem(
            id: unhashed.id,
            type: unhashed.type,
            title: unhashed.title,
            status: unhashed.status,
            credentialId: unhashed.credentialId,
            issuerDid: unhashed.issuerDid,
            subjectDid: unhashed.subjectDid,
            issuedAt: unhashed.issuedAt,
            expiresAt: unhashed.expiresAt,
            credentialHash: unhashed.credentialHash,
            hasSignature: unhashed.hasSignature,
            proofHash: proofHash(for: unhashed),
            sharedPayload: unhashed.sharedPayload,
            note: nil
        )
    }

    private static func proofHash(for item: SharedDocumentItem) -> String {
        let seed = [
            item.id,
            item.type.rawValue,
            item.title,
            item.credentialId ?? "",
            item.issuerDid ?? "",
            item.subjectDid ?? "",
            item.issuedAt.map(String.init) ?? "",
            item.expiresAt.map(String.init) ?? "",
            item.credentialHash ?? "",
            item.hasSignature ? "1" : "0",
            item.sharedPayload ?? ""
        ].joined(separator: "|")

        let digest = SHA256.hash(data: Data(seed.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func verifyProofHash(_ item: SharedDocumentItem) -> Bool {
        guard let hash = item.proofHash else { return false }
        return hash == proofHash(for: item)
    }

    private static func verifySignature(
        message: Data,
        signatureBase64: String,
        publicKeyBase64: String
    ) -> Bool {
        guard let signatureData = Data(base64Encoded: signatureBase64),
              let publicKeyData = Data(base64Encoded: publicKeyBase64),
              let publicKey = try? P256.Signing.PublicKey(x963Representation: publicKeyData),
              let signature = try? P256.Signing.ECDSASignature(derRepresentation: signatureData) else {
            return false
        }
        return publicKey.isValidSignature(signature, for: message)
    }

    private static func fallbackCredentialPayload(_ credential: Credential) -> String {
        struct Export: Codable {
            let id: String
            let type: String
            let title: String
            let issuerDid: String
            let subjectDid: String
            let issuedAt: Int
            let expiresAt: Int?
            let status: String
            let hash: String
            let signature: String?
        }

        let export = Export(
            id: credential.id,
            type: credential.type.rawValue,
            title: credential.title,
            issuerDid: credential.issuerDid,
            subjectDid: credential.subjectDid,
            issuedAt: Int(credential.issuedAt.timeIntervalSince1970),
            expiresAt: credential.expiresAt.map { Int($0.timeIntervalSince1970) },
            status: credential.status.rawValue,
            hash: credential.hash,
            signature: credential.signature
        )

        return (try? encodeCanonical(export)) ?? ""
    }

    private static func encodeCanonical<T: Encodable>(_ value: T) throws -> String {
        let data = try encodeCanonicalData(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "UTF-8 encoding failed"))
        }
        return string
    }

    private static func encodeCanonicalData<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    private static func randomNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private struct UnsignedResponsePayload: Codable {
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
    }
}

enum PaperlessIssueStatus {
    case issued
    case blocked
}

struct PaperlessIssueDecision {
    let status: PaperlessIssueStatus
    let record: PaperlessLedgerRecord?
    let message: String
    let mlRiskScore: Int
    let mlSignals: [String]

    var isIssued: Bool { status == .issued }
}

enum PaperlessCodeVerificationStatus {
    case verified
    case expired
    case invalidCode
}

struct PaperlessCodeVerificationResult {
    let status: PaperlessCodeVerificationStatus
    let record: PaperlessLedgerRecord?
    let message: String
    let mlRiskScore: Int
    let mlSignals: [String]

    var isVerified: Bool { status == .verified }
}

struct PaperlessLedgerRecord: Identifiable, Codable, Hashable {
    let id: String
    let issuer: VerificationIssuerProfile
    let documentType: PaperlessDocumentType
    let title: String
    let subjectName: String
    let subjectDid: String
    let payloadHash: String
    let issuerSignatureHash: String
    let verificationCode: String
    let createdAt: Date
    let expiresAt: Date?
    var verificationCount: Int
    var lastVerifiedAt: Date?
    let mlRiskScoreAtIssue: Int
    let mlWarningAtIssue: String?
    let attachment: PaperlessFileAttachment?
}

struct PaperlessFileAttachment: Codable, Hashable {
    let id: String
    let fileName: String
    let mimeType: String
    let fileSizeBytes: Int64
    let sha256: String
    let relativePath: String
}

struct WalletDocumentTransferPayload: Codable, Hashable {
    let v: Int
    let t: String
    let transferId: String
    let verificationCode: String
    let issuerDid: String
    let issuerName: String
    let issuerHandle: String
    let issuerRole: String
    let recipientDid: String
    let recipientName: String
    let documentType: String
    let title: String
    let attachmentFileName: String?
    let attachmentMimeType: String?
    let attachmentSha256: String?
    let createdAt: Int
    let nonce: String
    let hash: String
}

private struct PaperlessVerificationEvent: Codable, Hashable {
    let id: String
    let codeKey: String
    let checkedAt: Date
    let wasValid: Bool
}

private enum PaperlessAttachmentError: LocalizedError {
    case invalidSourceFile
    case failedToCopyFile
    case missingStagedFile

    var errorDescription: String? {
        switch self {
        case .invalidSourceFile:
            return "Invalid source file. Please choose a valid document."
        case .failedToCopyFile:
            return "Unable to import the selected document into app storage."
        case .missingStagedFile:
            return "The selected staged document could not be found. Please re-upload it."
        }
    }
}

private enum PaperlessAttachmentPaths {
    static var docsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func absoluteURL(for relativePath: String) -> URL {
        docsDir.appendingPathComponent(relativePath)
    }

    static func ensureParentDirectory(for fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    static func sanitizeFileName(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let sanitizedScalars = raw.unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "_"
        }
        let candidate = String(sanitizedScalars).trimmingCharacters(in: .whitespacesAndNewlines)
        return candidate.isEmpty ? "document.bin" : candidate
    }

    static func sanitizePathComponent(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = String(raw.unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "_"
        })
        let trimmed = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "unknown" : trimmed
    }
}

actor PaperlessDocumentLedgerService {
    static let shared = PaperlessDocumentLedgerService()
    private init() {}

    private var recordsByCodeKey: [String: PaperlessLedgerRecord] = [:]
    private var verificationEvents: [PaperlessVerificationEvent] = []
    private var hasLoadedFromDisk = false

    private static var docsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private static var recordsURL: URL { docsDir.appendingPathComponent("paperless_document_ledger.json") }
    private static var eventsURL: URL { docsDir.appendingPathComponent("paperless_document_verifications.json") }

    private static let stagedAttachmentPrefix = "paperless_attachment_staging"
    private static let ledgerAttachmentPrefix = "paperless_ledger_attachments"

    func issuerProfiles() -> [VerificationIssuerProfile] {
        PaperlessDocumentType.allCases.map(\.verifiedIssuerProfile)
    }

    func seedDemoDataIfNeeded() {
        ensureLoaded()
    }

    func importDocumentForIssuance(from sourceURL: URL) throws -> PaperlessFileAttachment {
        ensureLoaded()

        guard sourceURL.isFileURL else {
            throw PaperlessAttachmentError.invalidSourceFile
        }

        let sourceName = sourceURL.lastPathComponent.isEmpty ? "uploaded_document.bin" : sourceURL.lastPathComponent
        let safeName = PaperlessAttachmentPaths.sanitizeFileName(sourceName)
        let relativePath = "\(Self.stagedAttachmentPrefix)/\(UUID().uuidString)_\(safeName)"
        let destinationURL = PaperlessAttachmentPaths.absoluteURL(for: relativePath)

        do {
            try PaperlessAttachmentPaths.ensureParentDirectory(for: destinationURL)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            do {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            } catch {
                let data = try Data(contentsOf: sourceURL)
                try data.write(to: destinationURL, options: .atomic)
            }

            let attrs = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
            let fileSize = (attrs[.size] as? NSNumber)?.int64Value ?? 0
            let fileData = try Data(contentsOf: destinationURL)
            let hash = Self.sha256Hex(fileData)
            let mimeType = Self.mimeType(for: destinationURL)

            return PaperlessFileAttachment(
                id: UUID().uuidString,
                fileName: safeName,
                mimeType: mimeType,
                fileSizeBytes: fileSize,
                sha256: hash,
                relativePath: relativePath
            )
        } catch {
            try? FileManager.default.removeItem(at: destinationURL)
            throw PaperlessAttachmentError.failedToCopyFile
        }
    }

    func discardStagedIssueDocument(_ attachment: PaperlessFileAttachment) {
        guard attachment.relativePath.hasPrefix(Self.stagedAttachmentPrefix + "/") else {
            return
        }

        let url = PaperlessAttachmentPaths.absoluteURL(for: attachment.relativePath)
        try? FileManager.default.removeItem(at: url)
    }

    func issueDocument(
        issuer _: VerificationIssuerProfile,
        issuerWalletDid: String,
        documentType: PaperlessDocumentType,
        title: String,
        subjectName: String,
        subjectDid: String,
        documentBody: String,
        stagedAttachment: PaperlessFileAttachment?,
        expiresInDays: Int?
    ) -> PaperlessIssueDecision {
        ensureLoaded()

        let now = Date()
        // Enforce trusted issuer identity from document type regardless of caller input.
        let secureIssuer = documentType.verifiedIssuerProfile
        let normalizedWalletDid = Self.clean(issuerWalletDid, fallback: "did:sov:unknown").lowercased()

        guard documentType.isAuthorizedIssuerDid(normalizedWalletDid) else {
            let allowedDids = documentType.authorizedIssuerDIDs.sorted().joined(separator: ", ")
            return PaperlessIssueDecision(
                status: .blocked,
                record: nil,
                message: "Unauthorized issuer wallet DID for \(documentType.label). Allowed issuer DIDs: \(allowedDids).",
                mlRiskScore: 100,
                mlSignals: ["unauthorized_issuer_wallet"]
            )
        }

        let normalizedTitle = Self.clean(title, fallback: documentType.label)
        let normalizedName = Self.clean(subjectName, fallback: "Unknown Subject")
        let normalizedDid = Self.clean(subjectDid, fallback: "did:sov:unknown")
        let normalizedBody = Self.clean(documentBody, fallback: "No body provided")

        guard let stagedAttachment else {
            return PaperlessIssueDecision(
                status: .blocked,
                record: nil,
                message: "Upload a real document file before issuing.",
                mlRiskScore: 70,
                mlSignals: ["missing_document_upload"]
            )
        }

        let payloadHash = Self.sha256Hex(
            [
                secureIssuer.did.lowercased(),
                documentType.rawValue,
                normalizedTitle.lowercased(),
                normalizedName.lowercased(),
                normalizedDid.lowercased(),
                normalizedBody.lowercased(),
                stagedAttachment.sha256.lowercased()
            ].joined(separator: "|")
        )

        let issueRisk = evaluateIssueRisk(
            issuerDid: secureIssuer.did,
            payloadHash: payloadHash,
            at: now
        )

        if issueRisk.riskScore >= 80 {
            return PaperlessIssueDecision(
                status: .blocked,
                record: nil,
                message: "Blocked by ML policy: too many documents issued in a short time.",
                mlRiskScore: issueRisk.riskScore,
                mlSignals: issueRisk.signals.map(\.label)
            )
        }

        let codeKey = uniqueCodeKey(payloadHash: payloadHash, issuerDid: secureIssuer.did, now: now)
        let verificationCode = Self.displayCode(fromCodeKey: codeKey)
        let issuerSignatureHash = Self.sha256Hex(
            "\(secureIssuer.did.lowercased())|\(payloadHash)|\(codeKey)|\(Self.randomNonce())"
        )

        let recordId = UUID().uuidString
        let attachment: PaperlessFileAttachment
        do {
            attachment = try promoteStagedAttachment(stagedAttachment, recordId: recordId)
        } catch {
            return PaperlessIssueDecision(
                status: .blocked,
                record: nil,
                message: error.localizedDescription,
                mlRiskScore: 90,
                mlSignals: ["document_storage_failed"]
            )
        }

        let record = PaperlessLedgerRecord(
            id: recordId,
            issuer: secureIssuer,
            documentType: documentType,
            title: normalizedTitle,
            subjectName: normalizedName,
            subjectDid: normalizedDid,
            payloadHash: payloadHash,
            issuerSignatureHash: issuerSignatureHash,
            verificationCode: verificationCode,
            createdAt: now,
            expiresAt: expiresInDays.map { now.addingTimeInterval(Double($0) * 86_400) },
            verificationCount: 0,
            lastVerifiedAt: nil,
            mlRiskScoreAtIssue: issueRisk.riskScore,
            mlWarningAtIssue: issueRisk.signals.first?.detail,
            attachment: attachment
        )

        recordsByCodeKey[codeKey] = record
        saveToDisk()

        return PaperlessIssueDecision(
            status: .issued,
            record: record,
            message: "Issued with cryptographic hash, uploaded document proof, and verification code.",
            mlRiskScore: issueRisk.riskScore,
            mlSignals: issueRisk.signals.map(\.label)
        )
    }

    func createWalletTransferPayload(verificationCode: String) -> String? {
        ensureLoaded()

        let codeKey = Self.codeKey(fromAnyCode: verificationCode)
        guard let record = recordsByCodeKey[codeKey] else { return nil }

        let now = Date()
        let nonce = Self.randomNonce()
        let createdAt = Int(now.timeIntervalSince1970)

        let base = WalletDocumentTransferPayload(
            v: 1,
            t: "wallet_doc_transfer",
            transferId: UUID().uuidString,
            verificationCode: record.verificationCode,
            issuerDid: record.issuer.did,
            issuerName: record.issuer.displayName,
            issuerHandle: record.issuer.handle,
            issuerRole: record.issuer.roleLabel,
            recipientDid: record.subjectDid,
            recipientName: record.subjectName,
            documentType: record.documentType.rawValue,
            title: record.title,
            attachmentFileName: record.attachment?.fileName,
            attachmentMimeType: record.attachment?.mimeType,
            attachmentSha256: record.attachment?.sha256,
            createdAt: createdAt,
            nonce: nonce,
            hash: ""
        )

        let hash = Self.walletTransferHash(base)
        let payload = WalletDocumentTransferPayload(
            v: base.v,
            t: base.t,
            transferId: base.transferId,
            verificationCode: base.verificationCode,
            issuerDid: base.issuerDid,
            issuerName: base.issuerName,
            issuerHandle: base.issuerHandle,
            issuerRole: base.issuerRole,
            recipientDid: base.recipientDid,
            recipientName: base.recipientName,
            documentType: base.documentType,
            title: base.title,
            attachmentFileName: base.attachmentFileName,
            attachmentMimeType: base.attachmentMimeType,
            attachmentSha256: base.attachmentSha256,
            createdAt: base.createdAt,
            nonce: base.nonce,
            hash: hash
        )

        return try? Self.encodeCanonical(payload)
    }

    func parseWalletTransfer(raw: String) -> WalletDocumentTransferPayload? {
        ensureLoaded()

        guard let data = raw.data(using: .utf8),
              let payload = try? JSONDecoder().decode(WalletDocumentTransferPayload.self, from: data),
              payload.t == "wallet_doc_transfer" else {
            return nil
        }

        let expected = WalletDocumentTransferPayload(
            v: payload.v,
            t: payload.t,
            transferId: payload.transferId,
            verificationCode: payload.verificationCode,
            issuerDid: payload.issuerDid,
            issuerName: payload.issuerName,
            issuerHandle: payload.issuerHandle,
            issuerRole: payload.issuerRole,
            recipientDid: payload.recipientDid,
            recipientName: payload.recipientName,
            documentType: payload.documentType,
            title: payload.title,
            attachmentFileName: payload.attachmentFileName,
            attachmentMimeType: payload.attachmentMimeType,
            attachmentSha256: payload.attachmentSha256,
            createdAt: payload.createdAt,
            nonce: payload.nonce,
            hash: ""
        )

        guard Self.walletTransferHash(expected) == payload.hash else {
            return nil
        }

        let codeKey = Self.codeKey(fromAnyCode: payload.verificationCode)
        guard recordsByCodeKey[codeKey] != nil else {
            return nil
        }

        return payload
    }

    func verifyCode(_ code: String) -> PaperlessCodeVerificationResult {
        ensureLoaded()

        let codeKey = Self.codeKey(fromAnyCode: code)
        let now = Date()

        guard var record = recordsByCodeKey[codeKey] else {
            verificationEvents.append(
                PaperlessVerificationEvent(
                    id: UUID().uuidString,
                    codeKey: codeKey,
                    checkedAt: now,
                    wasValid: false
                )
            )
            trimEvents()
            saveToDisk()

            let invalidSignals = invalidAttemptSignals(at: now)
            let invalidRisk = invalidSignals.reduce(into: 0) { partial, signal in
                switch signal.severity {
                case .low: partial += 10
                case .medium: partial += 25
                case .high: partial += 40
                case .critical: partial += 60
                }
            }

            return PaperlessCodeVerificationResult(
                status: .invalidCode,
                record: nil,
                message: "Invalid verification code. Certificate is not registered.",
                mlRiskScore: min(100, invalidRisk),
                mlSignals: invalidSignals.map(\.label)
            )
        }

        let isExpired = record.expiresAt.map { $0 < now } ?? false
        record.verificationCount += 1
        record.lastVerifiedAt = now
        recordsByCodeKey[codeKey] = record

        verificationEvents.append(
            PaperlessVerificationEvent(
                id: UUID().uuidString,
                codeKey: codeKey,
                checkedAt: now,
                wasValid: !isExpired
            )
        )
        trimEvents()
        saveToDisk()

        var signals: [FraudSignal] = []
        let verificationBurst = verificationEvents.filter {
            $0.codeKey == codeKey && $0.checkedAt >= now.addingTimeInterval(-3_600)
        }.count
        if verificationBurst > 30 {
            signals.append(
                FraudSignal(
                    id: .rapidPosting,
                    label: "Unusual Verification Burst",
                    severity: .high,
                    detail: "This certificate was checked \(verificationBurst)x in the last hour",
                    remediation: "Audit where this code is being shared"
                )
            )
        }
        if let warning = record.mlWarningAtIssue {
            signals.append(
                FraudSignal(
                    id: .rapidPosting,
                    label: "Issuer ML Advisory",
                    severity: record.mlRiskScoreAtIssue > 60 ? .high : .medium,
                    detail: warning,
                    remediation: "Ask issuer to re-confirm this proof before mass sharing"
                )
            )
        }

        let risk = min(100, (record.mlRiskScoreAtIssue / 2) + (signals.count * 12))

        if isExpired {
            return PaperlessCodeVerificationResult(
                status: .expired,
                record: record,
                message: "Code is valid but this document is expired.",
                mlRiskScore: risk,
                mlSignals: signals.map(\.label)
            )
        }

        return PaperlessCodeVerificationResult(
            status: .verified,
            record: record,
            message: "Verified by \(record.issuer.displayName) (\(record.issuer.did)).",
            mlRiskScore: risk,
            mlSignals: signals.map(\.label)
        )
    }

    func feedPosts(limit: Int = 100) -> [Post] {
        ensureLoaded()

        let records = recordsByCodeKey.values
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)

        return records.map { record in
            let trustState: TrustState
            if record.mlRiskScoreAtIssue >= 75 {
                trustState = .suspicious
            } else if record.mlRiskScoreAtIssue >= 45 {
                trustState = .trusted
            } else {
                trustState = .verified
            }

            var analysis: FraudAnalysis?
            if record.mlRiskScoreAtIssue > 30 {
                let severity: FraudSeverity = record.mlRiskScoreAtIssue > 70 ? .high : .medium
                analysis = FraudAnalysis(
                    trustState: trustState,
                    signals: [
                        FraudSignal(
                            id: .rapidPosting,
                            label: "Issuance Velocity Monitor",
                            severity: severity,
                            detail: record.mlWarningAtIssue ?? "Issuer activity monitored by ML anti-spam policy",
                            remediation: "Use limited audience sharing when posting on social platforms"
                        )
                    ],
                    riskScore: record.mlRiskScoreAtIssue,
                    analysedAt: Date()
                )
            }

            let proof = DocumentProofMetadata(
                recordId: record.id,
                documentType: record.documentType,
                title: record.title,
                subjectName: record.subjectName,
                subjectDid: record.subjectDid,
                issuerDid: record.issuer.did,
                issuerAccountId: record.issuer.id,
                issuerRole: record.issuer.roleLabel,
                verificationCode: record.verificationCode,
                payloadHash: record.payloadHash,
                issuerSignatureHash: record.issuerSignatureHash,
                issuedAt: record.createdAt,
                expiresAt: record.expiresAt,
                verificationCount: record.verificationCount,
                mlRiskScore: record.mlRiskScoreAtIssue,
                mlWarning: record.mlWarningAtIssue
            )

            return Post(
                id: "doc-post-\(record.id)",
                content: "\(record.documentType.label) for \(record.subjectName) issued digitally. Use code \(record.verificationCode) to verify this proof before accepting it on LinkedIn or any portal.",
                author: record.issuer.asAuthor,
                sourceUrl: proof.verificationURL,
                sourceName: "Paperless Verification Ledger",
                publishedAt: record.createdAt,
                verificationStatus: .verifiedAuthor,
                trustState: trustState,
                claimCount: 3,
                verifiedClaimCount: trustState == .suspicious ? 1 : 3,
                tags: ["paperless", "verified-doc", record.documentType.rawValue],
                documentProof: proof,
                fraudAnalysis: analysis
            )
        }
    }

    private func evaluateIssueRisk(
        issuerDid: String,
        payloadHash: String,
        at now: Date
    ) -> (riskScore: Int, signals: [FraudSignal]) {
        let hourAgo = now.addingTimeInterval(-3_600)
        let issuerRecentCount = recordsByCodeKey.values.filter {
            $0.issuer.did == issuerDid && $0.createdAt >= hourAgo
        }.count
        let duplicateCount = recordsByCodeKey.values.filter { $0.payloadHash == payloadHash }.count

        var signals: [FraudSignal] = []
        var risk = 0

        if issuerRecentCount >= 4 {
            let severity: FraudSeverity = issuerRecentCount >= 8 ? .high : .medium
            signals.append(
                FraudSignal(
                    id: .rapidPosting,
                    label: "High Issuance Velocity",
                    severity: severity,
                    detail: "Issuer created \(issuerRecentCount) documents in the last hour",
                    remediation: "Throttle issuance or require additional review"
                )
            )
            risk += issuerRecentCount >= 8 ? 75 : 45
        }

        if duplicateCount > 0 {
            let severity: FraudSeverity = duplicateCount > 2 ? .high : .medium
            signals.append(
                FraudSignal(
                    id: .credentialMismatch,
                    label: "Duplicate Document Fingerprint",
                    severity: severity,
                    detail: "This payload hash already exists \(duplicateCount)x in ledger",
                    remediation: "Confirm the source document before mass sharing"
                )
            )
            risk += duplicateCount > 2 ? 30 : 20
        }

        return (min(100, risk), signals)
    }

    private func invalidAttemptSignals(at now: Date) -> [FraudSignal] {
        let tenMinutesAgo = now.addingTimeInterval(-600)
        let invalidCount = verificationEvents.filter {
            !$0.wasValid && $0.checkedAt >= tenMinutesAgo
        }.count

        guard invalidCount >= 4 else { return [] }

        let severity: FraudSeverity = invalidCount >= 10 ? .critical : .high
        return [
            FraudSignal(
                id: .rapidPosting,
                label: "Code Enumeration Pattern",
                severity: severity,
                detail: "\(invalidCount) invalid verification attempts in 10 minutes",
                remediation: "Rate-limit unknown code checks"
            )
        ]
    }

    private func loadFromDisk() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = try? Data(contentsOf: Self.recordsURL),
           let records = try? decoder.decode([PaperlessLedgerRecord].self, from: data) {
            var map: [String: PaperlessLedgerRecord] = [:]
            for record in records {
                map[Self.codeKey(fromAnyCode: record.verificationCode)] = record
            }
            recordsByCodeKey = map
        }

        if let data = try? Data(contentsOf: Self.eventsURL),
           let events = try? decoder.decode([PaperlessVerificationEvent].self, from: data) {
            verificationEvents = events
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

        let records = Array(recordsByCodeKey.values).sorted { $0.createdAt > $1.createdAt }
        if let data = try? encoder.encode(records) {
            try? data.write(to: Self.recordsURL, options: .atomic)
        }

        if let data = try? encoder.encode(verificationEvents) {
            try? data.write(to: Self.eventsURL, options: .atomic)
        }
    }

    private func trimEvents(maxCount: Int = 2_000) {
        guard verificationEvents.count > maxCount else { return }
        verificationEvents = Array(verificationEvents.suffix(maxCount))
    }

    private func uniqueCodeKey(payloadHash: String, issuerDid: String, now: Date) -> String {
        var attempt = 0
        while true {
            let seed = "\(issuerDid.lowercased())|\(payloadHash)|\(Int(now.timeIntervalSince1970))|\(attempt)|\(Self.randomNonce())"
            let digest = Self.sha256Hex(seed).uppercased()
            let candidate = "ST\(String(digest.prefix(12)))"
            if recordsByCodeKey[candidate] == nil {
                return candidate
            }
            attempt += 1
        }
    }

    private static func displayCode(fromCodeKey key: String) -> String {
        let cleaned = codeKey(fromAnyCode: key)
        guard cleaned.count >= 14 else { return cleaned }
        let body = String(cleaned.dropFirst(2))
        let first = String(body.prefix(6))
        let second = String(body.dropFirst(6).prefix(6))
        return "ST-\(first)-\(second)"
    }

    private static func walletTransferHash(_ payload: WalletDocumentTransferPayload) -> String {
        let seed = [
            String(payload.v),
            payload.t,
            payload.transferId,
            codeKey(fromAnyCode: payload.verificationCode),
            payload.issuerDid.lowercased(),
            payload.issuerName.lowercased(),
            payload.issuerRole.lowercased(),
            payload.recipientDid.lowercased(),
            payload.documentType,
            payload.title.lowercased(),
            (payload.attachmentFileName ?? "").lowercased(),
            (payload.attachmentMimeType ?? "").lowercased(),
            (payload.attachmentSha256 ?? "").lowercased(),
            String(payload.createdAt),
            payload.nonce.lowercased()
        ].joined(separator: "|")
        return sha256Hex(seed)
    }

    private func promoteStagedAttachment(_ staged: PaperlessFileAttachment, recordId: String) throws -> PaperlessFileAttachment {
        let sourceURL = PaperlessAttachmentPaths.absoluteURL(for: staged.relativePath)
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw PaperlessAttachmentError.missingStagedFile
        }

        let safeFileName = PaperlessAttachmentPaths.sanitizeFileName(staged.fileName)
        let relativePath = "\(Self.ledgerAttachmentPrefix)/\(recordId)/\(safeFileName)"
        let destinationURL = PaperlessAttachmentPaths.absoluteURL(for: relativePath)

        do {
            try PaperlessAttachmentPaths.ensureParentDirectory(for: destinationURL)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)

            return PaperlessFileAttachment(
                id: staged.id,
                fileName: safeFileName,
                mimeType: staged.mimeType,
                fileSizeBytes: staged.fileSizeBytes,
                sha256: staged.sha256,
                relativePath: relativePath
            )
        } catch {
            throw PaperlessAttachmentError.failedToCopyFile
        }
    }

    private static func mimeType(for fileURL: URL) -> String {
        guard !fileURL.pathExtension.isEmpty,
              let utType = UTType(filenameExtension: fileURL.pathExtension) else {
            return "application/octet-stream"
        }
        return utType.preferredMIMEType ?? "application/octet-stream"
    }

    private static func encodeCanonical<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "UTF-8 encoding failed"))
        }
        return string
    }

    private static func codeKey(fromAnyCode code: String) -> String {
        String(code.uppercased().filter { $0.isLetter || $0.isNumber })
    }

    private static func clean(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private static func sha256Hex(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
}

struct WalletVerifiedDocument: Identifiable, Codable, Hashable {
    let id: String
    let ownerDid: String
    let verificationCode: String
    let documentType: PaperlessDocumentType
    let title: String
    let subjectName: String
    let subjectDid: String
    let issuerName: String
    let issuerDid: String
    let issuerRole: String
    let payloadHash: String
    let issuerSignatureHash: String
    let verificationCount: Int
    let receivedAt: Date
    let transferId: String
    let attachment: PaperlessFileAttachment?
}

actor WalletDocumentVaultService {
    static let shared = WalletDocumentVaultService()
    private init() {}

    private var documents: [WalletVerifiedDocument] = []
    private var hasLoaded = false

    private static var docsURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("wallet_verified_documents.json")
    }

    func saveVerifiedDocument(
        record: PaperlessLedgerRecord,
        ownerDid: String,
        transferId: String
    ) -> WalletVerifiedDocument {
        ensureLoaded()

        let normalizedCode = record.verificationCode.uppercased()
        documents.removeAll {
            $0.ownerDid.lowercased() == ownerDid.lowercased() &&
            $0.verificationCode.uppercased() == normalizedCode
        }

        let copiedAttachment = copyAttachmentToWallet(
            sourceAttachment: record.attachment,
            ownerDid: ownerDid,
            transferId: transferId
        )

        let saved = WalletVerifiedDocument(
            id: UUID().uuidString,
            ownerDid: ownerDid,
            verificationCode: record.verificationCode,
            documentType: record.documentType,
            title: record.title,
            subjectName: record.subjectName,
            subjectDid: record.subjectDid,
            issuerName: record.issuer.displayName,
            issuerDid: record.issuer.did,
            issuerRole: record.issuer.roleLabel,
            payloadHash: record.payloadHash,
            issuerSignatureHash: record.issuerSignatureHash,
            verificationCount: record.verificationCount,
            receivedAt: Date(),
            transferId: transferId,
            attachment: copiedAttachment
        )

        documents.insert(saved, at: 0)
        saveToDisk()
        return saved
    }

    func listDocuments(ownerDid: String) -> [WalletVerifiedDocument] {
        ensureLoaded()
        return documents
            .filter { $0.ownerDid.lowercased() == ownerDid.lowercased() }
            .sorted { $0.receivedAt > $1.receivedAt }
    }

    func documentFileURL(documentId: String, ownerDid: String) -> URL? {
        ensureLoaded()
        guard let document = documents.first(where: {
            $0.id == documentId && $0.ownerDid.lowercased() == ownerDid.lowercased()
        }),
        let attachment = document.attachment else {
            return nil
        }

        let fileURL = PaperlessAttachmentPaths.absoluteURL(for: attachment.relativePath)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    func deleteDocument(documentId: String, ownerDid: String) -> Bool {
        ensureLoaded()

        guard let index = documents.firstIndex(where: {
            $0.id == documentId && $0.ownerDid.lowercased() == ownerDid.lowercased()
        }) else {
            return false
        }

        let removed = documents.remove(at: index)
        if let attachment = removed.attachment {
            let fileURL = PaperlessAttachmentPaths.absoluteURL(for: attachment.relativePath)
            try? FileManager.default.removeItem(at: fileURL)
        }

        saveToDisk()
        return true
    }

    private func copyAttachmentToWallet(
        sourceAttachment: PaperlessFileAttachment?,
        ownerDid: String,
        transferId: String
    ) -> PaperlessFileAttachment? {
        guard let sourceAttachment else { return nil }

        let sourceURL = PaperlessAttachmentPaths.absoluteURL(for: sourceAttachment.relativePath)
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            return nil
        }

        let ownerComponent = PaperlessAttachmentPaths.sanitizePathComponent(ownerDid.lowercased())
        let safeName = PaperlessAttachmentPaths.sanitizeFileName(sourceAttachment.fileName)
        let relativePath = "paperless_wallet_attachments/\(ownerComponent)/\(transferId)_\(safeName)"
        let destinationURL = PaperlessAttachmentPaths.absoluteURL(for: relativePath)

        do {
            try PaperlessAttachmentPaths.ensureParentDirectory(for: destinationURL)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            return PaperlessFileAttachment(
                id: sourceAttachment.id,
                fileName: safeName,
                mimeType: sourceAttachment.mimeType,
                fileSizeBytes: sourceAttachment.fileSizeBytes,
                sha256: sourceAttachment.sha256,
                relativePath: relativePath
            )
        } catch {
            return nil
        }
    }

    private func ensureLoaded() {
        guard !hasLoaded else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: Self.docsURL),
           let loaded = try? decoder.decode([WalletVerifiedDocument].self, from: data) {
            documents = loaded
        }
        hasLoaded = true
    }

    private func saveToDisk() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(documents) {
            try? data.write(to: Self.docsURL, options: .atomic)
        }
    }
}
