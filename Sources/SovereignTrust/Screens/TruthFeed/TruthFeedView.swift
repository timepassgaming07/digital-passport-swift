import SwiftUI
import QuickLook
import UniformTypeIdentifiers

struct TruthFeedView: View {
    @State private var vm = TruthFeedViewModel()
    @State private var expandedId: String?
    @State private var fraudId: String?
    @State private var showReceiveScanner = false
    @State private var showIssueDocumentPicker = false
    @State private var previewAttachment: WalletAttachmentPreview?
    @State private var appState = AppState.shared

    var body: some View {
        ZStack {
            AmbientBackground(isDark: appState.isDarkMode).ignoresSafeArea()
            VStack(spacing: 0) {
                if vm.isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.stCyan))
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            paperlessHubCard

                            ForEach(vm.filtered) { post in
                                PostCard(post: post, isExpanded: expandedId == post.id, showFraud: fraudId == post.id) {
                                    withAnimation(.stSpring) {
                                        if expandedId == post.id {
                                            fraudId = fraudId == post.id ? nil : post.id
                                        } else {
                                            expandedId = post.id
                                            fraudId = nil
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 110)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Truth Feed")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showReceiveScanner) {
            ProductScannerSheet { payload in
                showReceiveScanner = false
                Task { await vm.stageWalletTransfer(rawPayload: payload) }
            }
        }
        .fileImporter(
            isPresented: $showIssueDocumentPicker,
            allowedContentTypes: [.pdf, .image, .text, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else {
                    vm.issueMessage = "No file selected."
                    return
                }
                Task { await vm.importIssueDocument(from: url) }
            case let .failure(error):
                vm.issueMessage = "Unable to import file: \(error.localizedDescription)"
            }
        }
        .sheet(item: $previewAttachment) { item in
            DocumentQuickLookPreview(url: item.url)
        }
        .task { await vm.load() }
    }

    private var paperlessHubCard: some View {
        GlassCard(cornerRadius: 24, glowColor: Color.stCyan, glowOpacity: 0.08, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.stCyan)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wallet Document Exchange")
                            .font(.stHeadline)
                            .foregroundStyle(Color.stPrimary)
                        Text("Issuer creates and signs report QR. User scans, verifies, then saves to wallet.")
                            .font(.stCaption)
                            .foregroundStyle(Color.stSecondary)
                    }
                }

                issuerWorkflowSection

                Divider().background(Color.white.opacity(0.1))

                userWorkflowSection

                Divider().background(Color.white.opacity(0.1))

                walletDocumentsSection
            }
        }
    }

    private var issuerWorkflowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Issuer Section")
                .font(.stHeadline)
                .foregroundStyle(Color.stPrimary)

            Picker(
                "Document Type",
                selection: Binding(
                    get: { vm.selectedDocumentType },
                    set: { vm.selectDocumentType($0) }
                )
            ) {
                ForEach(PaperlessDocumentType.allCases, id: \.self) { type in
                    Text(type.label).tag(type)
                }
            }
            .pickerStyle(.segmented)

            GlassCard(cornerRadius: 14, glowColor: Color.stGreen, glowOpacity: 0.05, innerPadding: 10) {
                VStack(alignment: .leading, spacing: 7) {
                    profileRow("Issuer Name", vm.issuerProfile.displayName)
                    profileRow("Issuer DID", vm.issuerProfile.did, mono: true)
                    profileRow("Institution", vm.issuerProfile.institution)
                    profileRow("Role", vm.issuerRoleLabel, valueTone: Color.stGreen)
                    profileRow(
                        "Active Wallet DID",
                        vm.activeWalletDid,
                        mono: true,
                        valueTone: vm.issuerAuthorizedForSelection ? Color.stGreen : Color.stRed
                    )
                }
            }

            Text(vm.issuerAuthorizationMessage)
                .font(.stCaption)
                .foregroundStyle(vm.issuerAuthorizedForSelection ? Color.stGreen : Color.stRed)

            GlassCard(cornerRadius: 12, glowColor: Color.stCyan, glowOpacity: 0.04, innerPadding: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Wallet Issuer Permissions")
                        .font(.stCaption)
                        .foregroundStyle(Color.stTertiary)
                    Text(vm.authorizedIssuerRolesSummary)
                        .font(.stMonoSm)
                        .foregroundStyle(Color.stPrimary)
                }
            }

            GlassCard(cornerRadius: 14, glowColor: Color.stCyan, glowOpacity: 0.06, innerPadding: 10) {
                VStack(alignment: .leading, spacing: 7) {
                    profileRow("Recipient Name", vm.subjectName)
                    profileRow("Recipient DID", vm.subjectDid, mono: true)
                }
            }

            GlassTextField(placeholder: "Report Title", text: $vm.documentTitle, icon: vm.selectedDocumentType.icon)

            GlassButton(
                label: vm.selectedIssueAttachment == nil ? "Select Document (PDF/Image)" : "Replace Attached Document",
                icon: "doc.badge.plus",
                variant: .secondary,
                isLoading: vm.isImportingIssueAttachment,
                fullWidth: true
            ) {
                showIssueDocumentPicker = true
            }

            if let attachment = vm.selectedIssueAttachment {
                GlassCard(cornerRadius: 14, glowColor: Color.stGreen, glowOpacity: 0.05, innerPadding: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        profileRow("Attached File", attachment.fileName)
                        profileRow("MIME Type", attachment.mimeType)
                        profileRow("Size", fileSizeString(attachment.fileSizeBytes))
                        profileRow("SHA-256", Formatters.shortHash(attachment.sha256), mono: true, valueTone: Color.stGreen)
                    }
                }

                GlassButton(
                    label: "Remove Attached File",
                    icon: "trash",
                    variant: .danger,
                    fullWidth: true
                ) {
                    Task { await vm.clearIssueDocumentSelection() }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Report Details")
                    .font(.stCaption)
                    .foregroundStyle(Color.stTertiary)
                TextEditor(text: $vm.documentBody)
                    .frame(minHeight: 76)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(Color.stPrimary)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }

            GlassButton(
                label: "Verify & Issue Document",
                icon: "paperplane.fill",
                isLoading: vm.isIssuingDocument,
                fullWidth: true
            ) {
                Task { await vm.issueDocument() }
            }
            .disabled(
                !vm.issuerAuthorizedForSelection ||
                vm.isIssuingDocument ||
                vm.isImportingIssueAttachment ||
                vm.selectedIssueAttachment == nil
            )
            .opacity(vm.issuerAuthorizedForSelection && vm.selectedIssueAttachment != nil ? 1 : 0.6)

            if let message = vm.issueMessage {
                Text(message)
                    .font(.stCaption)
                    .foregroundStyle(Color.stSecondary)
            }

            if let code = vm.latestIssuedCode {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Verification Code")
                        .font(.stCaption)
                        .foregroundStyle(Color.stTertiary)
                    Text(code)
                        .font(.stMono)
                        .foregroundStyle(Color.stCyan)
                        .textSelection(.enabled)
                }

                GlassButton(
                    label: "Generate Transfer QR",
                    icon: "qrcode",
                    variant: .secondary,
                    isLoading: vm.isPreparingTransfer,
                    fullWidth: true
                ) {
                    Task { await vm.prepareWalletTransfer() }
                }

                if let payload = vm.latestTransferPayload,
                   let qrImage = QRGeneratorService.generate(from: payload, size: 220) {
                    GlassCard(cornerRadius: 18, glowColor: Color.stGreen, glowOpacity: 0.08, innerPadding: 12) {
                        VStack(spacing: 8) {
                            Text("ISSUER QR")
                                .font(.stLabel)
                                .foregroundStyle(Color.stGreen)
                                .stWideTracked()
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            if let record = vm.latestIssuedRecord {
                                Text("Recipient DID: \(Formatters.shortDID(record.subjectDid))")
                                    .font(.stMonoSm)
                                    .foregroundStyle(Color.stSecondary)
                                Text("Recipient: \(record.subjectName)")
                                    .font(.stCaption)
                                    .foregroundStyle(Color.stSecondary)
                            }
                        }
                    }
                }
            }

            if let risk = vm.issueRiskScore {
                Text("ML issuance risk: \(risk)/100")
                    .font(.stCaption)
                    .foregroundStyle(risk > 70 ? Color.stRed : risk > 40 ? Color.stGold : Color.stGreen)
            }

            if !vm.issueMLSignals.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(vm.issueMLSignals, id: \.self) { signal in
                        Text("• \(signal)")
                            .font(.stMonoSm)
                            .foregroundStyle(Color.stOrange)
                    }
                }
            }
        }
    }

    private var userWorkflowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("User Section")
                .font(.stHeadline)
                .foregroundStyle(Color.stPrimary)

            GlassCard(cornerRadius: 14, glowColor: Color.stCyan, glowOpacity: 0.06, innerPadding: 10) {
                VStack(alignment: .leading, spacing: 7) {
                    profileRow("Wallet Owner", vm.subjectName)
                    profileRow("Wallet DID", vm.subjectDid, mono: true)
                }
            }

            GlassButton(
                label: "Scan Incoming QR",
                icon: "qrcode.viewfinder",
                variant: .secondary,
                fullWidth: true
            ) {
                showReceiveScanner = true
            }

            if let transfer = vm.pendingScannedTransfer {
                scannedTransferCard(transfer)

                GlassButton(
                    label: "Verify Report & Add To Wallet",
                    icon: "checkmark.shield.fill",
                    variant: .secondary,
                    isLoading: vm.isReceivingTransfer,
                    fullWidth: true
                ) {
                    Task { await vm.verifyScannedTransferAndSave() }
                }
            }

            if let receiveMessage = vm.receiveMessage {
                Text(receiveMessage)
                    .font(.stCaption)
                    .foregroundStyle(Color.stSecondary)
            }

            if let verification = vm.codeVerification {
                verificationCard(verification)
            }
        }
    }

    private var walletDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Wallet Documents")
                .font(.stHeadline)
                .foregroundStyle(Color.stPrimary)

            if vm.walletDocuments.isEmpty {
                Text("No received documents yet")
                    .font(.stCaption)
                    .foregroundStyle(Color.stTertiary)
            } else {
                ForEach(vm.walletDocuments) { doc in
                    GlassCard(cornerRadius: 14, glowColor: Color.stCyan, glowOpacity: 0.04, innerPadding: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(doc.title)
                                .font(.stCaption)
                                .foregroundStyle(Color.stPrimary)
                            Text("Verified by \(doc.issuerName) • \(doc.issuerRole)")
                                .font(.stMonoSm)
                                .foregroundStyle(Color.stSecondary)
                            Text("Issuer DID: \(Formatters.shortDID(doc.issuerDid))")
                                .font(.stMonoSm)
                                .foregroundStyle(Color.stTertiary)
                            Text("Code: \(doc.verificationCode)")
                                .font(.stMonoSm)
                                .foregroundStyle(Color.stTertiary)

                            if let attachment = doc.attachment {
                                Text("File: \(attachment.fileName)")
                                    .font(.stMonoSm)
                                    .foregroundStyle(Color.stSecondary)

                                GlassButton(
                                    label: "Open File",
                                    icon: "doc.text.magnifyingglass",
                                    variant: .secondary,
                                    fullWidth: true
                                ) {
                                    Task {
                                        if let url = await vm.walletDocumentURL(doc) {
                                            previewAttachment = WalletAttachmentPreview(title: doc.title, url: url)
                                        } else {
                                            vm.walletMessage = "File is missing from local storage for this document."
                                        }
                                    }
                                }
                            } else {
                                Text("No source file attached")
                                    .font(.stCaption)
                                    .foregroundStyle(Color.stTertiary)
                            }

                            GlassButton(
                                label: "Delete From Wallet",
                                icon: "trash",
                                variant: .danger,
                                isLoading: vm.isDeletingWalletDocument,
                                fullWidth: true
                            ) {
                                Task { await vm.deleteWalletDocument(doc) }
                            }
                        }
                    }
                }
            }

            if let walletMessage = vm.walletMessage {
                Text(walletMessage)
                    .font(.stCaption)
                    .foregroundStyle(Color.stSecondary)
            }
        }
    }

    private func scannedTransferCard(_ transfer: WalletDocumentTransferPayload) -> some View {
        let typeLabel = PaperlessDocumentType(rawValue: transfer.documentType)?.label ?? transfer.documentType

        return GlassCard(cornerRadius: 14, glowColor: Color.stGreen, glowOpacity: 0.06, innerPadding: 10) {
            VStack(alignment: .leading, spacing: 6) {
                profileRow("Report", transfer.title)
                profileRow("Type", typeLabel)
                profileRow("Issuer", transfer.issuerName)
                profileRow("Issuer DID", transfer.issuerDid, mono: true)
                profileRow("Verification Code", transfer.verificationCode, mono: true, valueTone: Color.stCyan)
                if let fileName = transfer.attachmentFileName {
                    profileRow("Attached File", fileName)
                }
            }
        }
    }

    private func profileRow(_ label: String, _ value: String, mono: Bool = false, valueTone: Color = .stPrimary) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.stCaption)
                .foregroundStyle(Color.stTertiary)
            Spacer(minLength: 8)
            Text(value)
                .font(mono ? .stMonoSm : .stCaption)
                .foregroundStyle(valueTone)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .textSelection(.enabled)
        }
    }

    private func verificationCard(_ result: PaperlessCodeVerificationResult) -> some View {
        let tone: Color = switch result.status {
        case .verified: .stGreen
        case .expired: .stGold
        case .invalidCode: .stRed
        }

        return GlassCard(cornerRadius: 18, glowColor: tone, glowOpacity: 0.12, innerPadding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: result.status == .verified ? "checkmark.seal.fill" : result.status == .expired ? "clock.badge.exclamationmark.fill" : "xmark.seal.fill")
                        .foregroundStyle(tone)
                    Text(result.message)
                        .font(.stCaption)
                        .foregroundStyle(Color.stSecondary)
                }

                if let record = result.record {
                    Text("Verified By: \(record.issuer.displayName)")
                        .font(.stCaption)
                        .foregroundStyle(Color.stPrimary)
                    Text("Issuer DID: \(Formatters.shortDID(record.issuer.did))")
                        .font(.stMonoSm)
                        .foregroundStyle(Color.stTertiary)
                    Text("Hash: \(Formatters.shortHash(record.payloadHash))")
                        .font(.stMonoSm)
                        .foregroundStyle(Color.stTertiary)
                }

                Text("ML risk: \(result.mlRiskScore)/100")
                    .font(.stCaption)
                    .foregroundStyle(result.mlRiskScore > 70 ? Color.stRed : result.mlRiskScore > 40 ? Color.stGold : Color.stGreen)

                if !result.mlSignals.isEmpty {
                    ForEach(result.mlSignals, id: \.self) { signal in
                        Text("• \(signal)")
                            .font(.stMonoSm)
                            .foregroundStyle(Color.stOrange)
                    }
                }
            }
        }
    }

    private func fileSizeString(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

private struct WalletAttachmentPreview: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
}

private struct DocumentQuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.url = url
        uiViewController.reloadData()
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}
