import Foundation
import Observation

enum FeedFilter: String, CaseIterable {
    case all = "All"
    case paperless = "Paperless"
    case verified   = "Verified"
    case suspicious = "Suspicious"
    case unverified = "Unverified"
}

@Observable
@MainActor
final class TruthFeedViewModel {
    var posts: [Post] = []
    var filtered: [Post] = []
    var filter: FeedFilter = .all
    var isLoading = false

    // Single-wallet issuance state
    var selectedDocumentType: PaperlessDocumentType = .medicalReport
    var documentTitle: String = ""
    var documentBody: String = ""
    var subjectName: String { Identity.mock.displayName }
    var subjectDid: String { Identity.mock.did }
    var verifyCodeInput: String = ""
    var issueMessage: String?
    var latestIssuedCode: String?
    var issueRiskScore: Int?
    var issueMLSignals: [String] = []
    var latestIssuedRecord: PaperlessLedgerRecord?
    var latestTransferPayload: String?
    var selectedIssueAttachment: PaperlessFileAttachment?
    var pendingScannedTransfer: WalletDocumentTransferPayload?
    var codeVerification: PaperlessCodeVerificationResult?
    var receiveMessage: String?
    var walletMessage: String?
    var walletDocuments: [WalletVerifiedDocument] = []
    var isImportingIssueAttachment = false
    var isIssuingDocument = false
    var isPreparingTransfer = false
    var isVerifyingCode = false
    var isReceivingTransfer = false
    var isDeletingWalletDocument = false

    var activeWalletDid: String {
        Identity.mock.did
    }

    var issuerProfile: VerificationIssuerProfile {
        selectedDocumentType.verifiedIssuerProfile
    }

    var issuerRoleLabel: String {
        selectedDocumentType.verifiedIssuerRole
    }

    var issuerAuthorizedForSelection: Bool {
        selectedDocumentType.isAuthorizedIssuerDid(activeWalletDid)
    }

    var authorizedIssuerTypesForWallet: [PaperlessDocumentType] {
        PaperlessDocumentType.authorizedDocumentTypes(for: activeWalletDid)
    }

    var authorizedIssuerRolesSummary: String {
        let roles = authorizedIssuerTypesForWallet.map(\.verifiedIssuerRole)
        if roles.isEmpty {
            return "No issuer permissions assigned to this wallet DID."
        }
        return roles.joined(separator: " • ")
    }

    var issuerAuthorizationMessage: String {
        if issuerAuthorizedForSelection {
            return "Authorized: this wallet DID has permission to issue \(selectedDocumentType.label)."
        }

        return "Unauthorized for \(selectedDocumentType.label). Choose a document type covered by your wallet issuer permissions."
    }

    func isIssuerAuthorized(for type: PaperlessDocumentType) -> Bool {
        type.isAuthorizedIssuerDid(activeWalletDid)
    }

    func load() async {
        isLoading = true

        if !issuerAuthorizedForSelection,
           let firstAuthorized = PaperlessDocumentType.allCases.first(where: { isIssuerAuthorized(for: $0) }) {
            selectedDocumentType = firstAuthorized
        }

        if documentTitle.isEmpty {
            applyDocumentTemplate(selectedDocumentType)
        }

        await refreshFeedData()
        await loadWalletDocuments()

        applyFilter(filter)
        isLoading = false
    }

    func selectDocumentType(_ type: PaperlessDocumentType) {
        selectedDocumentType = type
        applyDocumentTemplate(type)
    }

    func issueDocument() async {
        guard issuerAuthorizedForSelection else {
            issueMessage = issuerAuthorizationMessage
            issueRiskScore = 100
            issueMLSignals = ["unauthorized_issuer_wallet"]
            return
        }

        guard selectedIssueAttachment != nil else {
            issueMessage = "Upload a PDF/image/document file first, then verify and issue."
            issueRiskScore = 70
            issueMLSignals = ["missing_document_upload"]
            return
        }

        if documentTitle.isEmpty {
            applyDocumentTemplate(selectedDocumentType)
        }

        isIssuingDocument = true
        issueMessage = nil
        receiveMessage = nil

        do {
            let approved = try await BiometricService.shared.authenticate(
                reason: "Authenticate to sign and issue this document from your wallet"
            )
            guard approved else {
                issueMessage = "Issuance cancelled. Biometrics are required."
                isIssuingDocument = false
                return
            }
        } catch {
            issueMessage = error.localizedDescription
            isIssuingDocument = false
            return
        }

        let issuer = issuerProfile

        let decision = await PaperlessDocumentLedgerService.shared.issueDocument(
            issuer: issuer,
            issuerWalletDid: activeWalletDid,
            documentType: selectedDocumentType,
            title: documentTitle,
            subjectName: subjectName,
            subjectDid: subjectDid,
            documentBody: documentBody,
            stagedAttachment: selectedIssueAttachment,
            expiresInDays: selectedDocumentType == .certificate ? nil : 365
        )

        issueMessage = decision.message
        issueRiskScore = decision.mlRiskScore
        issueMLSignals = decision.mlSignals
        latestIssuedRecord = decision.record
        latestIssuedCode = decision.record?.verificationCode
        latestTransferPayload = nil
        pendingScannedTransfer = nil

        if decision.isIssued {
            selectedIssueAttachment = nil
        }

        if let code = decision.record?.verificationCode {
            verifyCodeInput = code
        }

        await refreshFeedData()
        applyFilter(filter)
        isIssuingDocument = false
    }

    func prepareWalletTransfer() async {
        guard let verificationCode = latestIssuedCode else {
            issueMessage = "Issue a document first before sending it via wallet QR."
            return
        }

        isPreparingTransfer = true
        receiveMessage = nil

        do {
            let approved = try await BiometricService.shared.authenticate(
                reason: "Authenticate to send this verified document to recipient wallet"
            )
            guard approved else {
                issueMessage = "Send cancelled. Biometrics are required."
                isPreparingTransfer = false
                return
            }
        } catch {
            issueMessage = error.localizedDescription
            isPreparingTransfer = false
            return
        }

        latestTransferPayload = await PaperlessDocumentLedgerService.shared.createWalletTransferPayload(
            verificationCode: verificationCode
        )

        if latestTransferPayload == nil {
            issueMessage = "Unable to prepare wallet transfer QR for this document."
        } else {
            issueMessage = "Wallet transfer QR ready. Recipient can scan to receive."
        }

        isPreparingTransfer = false
    }

    func importIssueDocument(from pickedURL: URL) async {
        isImportingIssueAttachment = true
        issueMessage = nil
        issueRiskScore = nil
        issueMLSignals = []

        let hasSecurityScope = pickedURL.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope {
                pickedURL.stopAccessingSecurityScopedResource()
            }
            isImportingIssueAttachment = false
        }

        if let previous = selectedIssueAttachment {
            await PaperlessDocumentLedgerService.shared.discardStagedIssueDocument(previous)
        }

        do {
            let imported = try await PaperlessDocumentLedgerService.shared.importDocumentForIssuance(from: pickedURL)
            selectedIssueAttachment = imported
            latestIssuedCode = nil
            latestIssuedRecord = nil
            latestTransferPayload = nil
            issueMessage = "Document uploaded. Tap Verify & Issue Document to create verifiable proof."
        } catch {
            issueMessage = error.localizedDescription
        }
    }

    func clearIssueDocumentSelection() async {
        guard let selectedIssueAttachment else { return }
        await PaperlessDocumentLedgerService.shared.discardStagedIssueDocument(selectedIssueAttachment)
        self.selectedIssueAttachment = nil
    }

    func stageWalletTransfer(rawPayload: String) async {
        receiveMessage = nil
        codeVerification = nil

        guard let transfer = await PaperlessDocumentLedgerService.shared.parseWalletTransfer(raw: rawPayload) else {
            receiveMessage = "Invalid wallet transfer QR payload."
            return
        }

        if transfer.recipientDid.lowercased() != Identity.mock.did.lowercased() {
            receiveMessage = "This transfer is addressed to a different wallet DID."
            return
        }

        pendingScannedTransfer = transfer
        receiveMessage = "Transfer scanned. Review details and tap Verify Report to add it to your wallet."
    }

    func verifyScannedTransferAndSave() async {
        guard let transfer = pendingScannedTransfer else {
            receiveMessage = "Scan a transfer QR first."
            return
        }

        isReceivingTransfer = true
        receiveMessage = nil

        do {
            let approved = try await BiometricService.shared.authenticate(
                reason: "Authenticate to verify this report and save it to your wallet"
            )
            guard approved else {
                receiveMessage = "Receive cancelled. Biometrics are required."
                isReceivingTransfer = false
                return
            }
        } catch {
            receiveMessage = error.localizedDescription
            isReceivingTransfer = false
            return
        }

        let result = await PaperlessDocumentLedgerService.shared.verifyCode(transfer.verificationCode)
        codeVerification = result

        guard result.status == .verified, let record = result.record else {
            receiveMessage = result.message
            isReceivingTransfer = false
            return
        }

        if result.mlRiskScore >= 85 {
            receiveMessage = "Blocked by ML risk policy. This transfer is too suspicious to accept."
            isReceivingTransfer = false
            return
        }

        _ = await WalletDocumentVaultService.shared.saveVerifiedDocument(
            record: record,
            ownerDid: Identity.mock.did,
            transferId: transfer.transferId
        )

        pendingScannedTransfer = nil
        receiveMessage = "Document received and saved in wallet. Verified by \(record.issuer.displayName)."
        await loadWalletDocuments()
        await refreshFeedData()
        applyFilter(filter)
        isReceivingTransfer = false
    }

    func receiveWalletTransfer(rawPayload: String) async {
        await stageWalletTransfer(rawPayload: rawPayload)
    }

    func walletDocumentURL(_ document: WalletVerifiedDocument) async -> URL? {
        await WalletDocumentVaultService.shared.documentFileURL(
            documentId: document.id,
            ownerDid: Identity.mock.did
        )
    }

    func deleteWalletDocument(_ document: WalletVerifiedDocument) async {
        isDeletingWalletDocument = true
        defer { isDeletingWalletDocument = false }

        let removed = await WalletDocumentVaultService.shared.deleteDocument(
            documentId: document.id,
            ownerDid: Identity.mock.did
        )

        if removed {
            walletMessage = "Deleted \(document.title) from wallet storage."
            await loadWalletDocuments()
        } else {
            walletMessage = "Unable to delete document."
        }
    }

    func verifyDocumentCode() async {
        let code = verifyCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            issueMessage = "Enter the certificate verification code first."
            return
        }

        isVerifyingCode = true
        receiveMessage = nil
        codeVerification = await PaperlessDocumentLedgerService.shared.verifyCode(code)
        await refreshFeedData()
        applyFilter(filter)
        isVerifyingCode = false
    }

    func applyFilter(_ f: FeedFilter) {
        filter = f
        filtered = switch f {
        case .all:
            posts
        case .paperless:
            posts.filter { $0.documentProof != nil }
        case .verified:
            posts.filter { $0.trustState == .verified || $0.trustState == .trusted }
        case .suspicious:
            posts.filter { $0.trustState == .suspicious || $0.trustState == .revoked }
        case .unverified:
            posts.filter { $0.trustState == .unknown || $0.trustState == .pending }
        }
    }

    func count(_ f: FeedFilter) -> Int {
        switch f {
        case .all:
            return posts.count
        case .paperless:
            return posts.filter { $0.documentProof != nil }.count
        case .verified:
            return posts.filter { $0.trustState == .verified || $0.trustState == .trusted }.count
        case .suspicious:
            return posts.filter { $0.trustState == .suspicious || $0.trustState == .revoked }.count
        case .unverified:
            return posts.filter { $0.trustState == .unknown || $0.trustState == .pending }.count
        }
    }

    private func refreshFeedData() async {
        let paperlessPosts = await PaperlessDocumentLedgerService.shared.feedPosts(limit: 100)
        var enriched = paperlessPosts.sorted { $0.publishedAt > $1.publishedAt }
        for i in enriched.indices {
            if enriched[i].fraudAnalysis == nil {
                enriched[i].fraudAnalysis = FraudSignalService.analyse(enriched[i])
            }
        }
        posts = enriched
    }

    private func loadWalletDocuments() async {
        walletDocuments = await WalletDocumentVaultService.shared.listDocuments(ownerDid: Identity.mock.did)
    }

    private func applyDocumentTemplate(_ type: PaperlessDocumentType) {
        switch type {
        case .medicalReport:
            documentTitle = "Medical Diagnostic Report"
            documentBody = "Verified by attending doctor. Includes diagnosis summary and recommended treatment plan."
        case .certificate:
            documentTitle = "Professional Certificate"
            documentBody = "Official completion certificate issued by the institution with cryptographic proof."
        case .employeeId:
            documentTitle = "Employee Verification ID"
            documentBody = "Active employee identity proof issued by HR for role and tenure validation."
        case .legalDocument:
            documentTitle = "Legal Attestation Document"
            documentBody = "Legally attested document signed and recorded for paperless validation."
        }
    }
}
