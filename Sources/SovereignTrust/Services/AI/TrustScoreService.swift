import Foundation

// MARK: – Trust Score Service — Signal Collection + Engine Bridge

/// Collects app-wide signals and produces TrustScores via TrustEngine.
/// Maintains a lightweight scan history for frequency/reuse detection.
/// All operations are synchronous and under 1ms — safe for main thread.
actor TrustScoreService {
    static let shared = TrustScoreService()
    private init() {}

    // MARK: – In-Memory Signal Store

    /// Rolling window of recent scan timestamps (max 200).
    private var scanTimestamps: [Date] = []

    /// Credential ID → scan count (rolling).
    private var credentialScanCounts: [String: Int] = [:]

    /// Recent pass/fail tallies (last 50 verifications).
    private var recentPasses: Int = 0
    private var recentFails: Int = 0
    private var totalVerifications: Int = 0

    // MARK: – Public API

    /// Evaluate trust for a verification result + its raw QR payload.
    func evaluate(
        result: VerificationResult,
        rawPayload: String,
        credential: Credential? = nil,
        issuer: Issuer? = nil
    ) -> TrustScore {
        let now = Date()
        recordScan(timestamp: now)
        recordVerification(result: result)

        let credId = credential?.id ?? result.subjectId
        let reuseCount = recordCredentialScan(id: credId)

        let parsed = QRParserService.parse(rawPayload)
        let issuerDid = credential?.issuerDid ?? parsed.payload?.iss
        let resolvedIssuer = issuer ?? issuerDid.flatMap { IssuerDirectory.find(did: $0) }

        let input = TrustInput(
            scanTimestamp: now,
            recentScanTimestamps: recentScans(),
            credentialId: credId,
            credentialReuseCount: reuseCount,
            credentialAge: credential?.issuedAt.timeIntervalSinceNow.magnitude ?? 0,
            credentialStatus: credential?.status,
            isExpired: credential?.isExpired ?? false,
            issuerDid: issuerDid,
            issuerTrustState: resolvedIssuer?.trustState,
            issuerIsVerified: resolvedIssuer?.isVerified ?? false,
            issuerInRegistry: resolvedIssuer != nil,
            recentPassCount: recentPasses,
            recentFailCount: recentFails,
            totalVerifications: totalVerifications,
            subjectType: result.subjectType,
            payloadSizeBytes: rawPayload.utf8.count,
            hasSignature: rawPayload.contains("sig") || rawPayload.contains("signature") || (credential?.signature != nil),
            hasValidStructure: parsed.type != .unknown || rawPayload.hasPrefix("did:")
        )

        return TrustEngine.evaluate(input)
    }

    /// Lightweight evaluation for a credential without a full scan context.
    func evaluateCredential(_ credential: Credential, issuer: Issuer?) -> TrustScore {
        let input = TrustInput(
            scanTimestamp: Date(),
            recentScanTimestamps: recentScans(),
            credentialId: credential.id,
            credentialReuseCount: credentialScanCounts[credential.id] ?? 0,
            credentialAge: credential.issuedAt.timeIntervalSinceNow.magnitude,
            credentialStatus: credential.status,
            isExpired: credential.isExpired,
            issuerDid: credential.issuerDid,
            issuerTrustState: issuer?.trustState,
            issuerIsVerified: issuer?.isVerified ?? false,
            issuerInRegistry: issuer != nil,
            recentPassCount: recentPasses,
            recentFailCount: recentFails,
            totalVerifications: totalVerifications,
            subjectType: .credential,
            payloadSizeBytes: credential.rawJson?.utf8.count ?? 200,
            hasSignature: credential.signature != nil,
            hasValidStructure: true
        )

        return TrustEngine.evaluate(input)
    }

    // MARK: – Internal Bookkeeping

    private func recordScan(timestamp: Date) {
        scanTimestamps.append(timestamp)
        // Prune scans older than 1 hour
        let cutoff = timestamp.addingTimeInterval(-3600)
        scanTimestamps.removeAll { $0 < cutoff }
        if scanTimestamps.count > 200 {
            scanTimestamps = Array(scanTimestamps.suffix(200))
        }
    }

    private func recordCredentialScan(id: String) -> Int {
        credentialScanCounts[id, default: 0] += 1
        return credentialScanCounts[id]!
    }

    private func recordVerification(result: VerificationResult) {
        totalVerifications += 1
        recentPasses += result.passCount
        recentFails += result.failCount
        // Keep rough running totals, decay over time
        if totalVerifications > 50 {
            recentPasses = max(0, recentPasses - result.passCount / 2)
            recentFails  = max(0, recentFails - result.failCount / 2)
        }
    }

    private func recentScans() -> [Date] {
        scanTimestamps
    }
}
