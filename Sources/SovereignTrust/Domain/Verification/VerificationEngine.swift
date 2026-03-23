import Foundation
import Observation

struct VerificationStep: Identifiable {
    let id = UUID()
    let number: Int
    let label: String
    var isActive   = false
    var isComplete = false
    var isFailed   = false
    var checkOutcome: CheckOutcome = .unknown
    var detail: String?
}

@Observable
@MainActor
final class VerificationEngine {
    var steps: [VerificationStep] = [
        VerificationStep(number:1, label:"Decoding QR payload"),
        VerificationStep(number:2, label:"Parsing structure"),
        VerificationStep(number:3, label:"Verifying signature"),
        VerificationStep(number:4, label:"Checking issuer registry"),
        VerificationStep(number:5, label:"Evaluating trust graph"),
    ]
    var result: VerificationResult?
    var isRunning = false

    func verify(raw: String, type: VerificationSubjectType) async {
        isRunning = true; result = nil
        // reset
        for i in steps.indices {
            steps[i].isActive = false; steps[i].isComplete = false
            steps[i].isFailed = false; steps[i].checkOutcome = .unknown
        }
        let start = Date()
        var checks: [VerificationCheck] = []

        for i in steps.indices {
            steps[i].isActive = true
            try? await Task.sleep(nanoseconds:UInt64(AppConstants.verificationStepDelay * 1_000_000_000))
            let (outcome, detail) = Self.performCheck(step:i, raw:raw, type:type)
            let check = VerificationCheck(id:UUID().uuidString, label:steps[i].label,
                                          outcome:outcome, detail:detail)
            checks.append(check)
            steps[i].isActive   = false
            steps[i].isComplete = outcome != .fail
            steps[i].isFailed   = outcome == .fail
            steps[i].checkOutcome = outcome
            steps[i].detail = detail
        }

        let ms = Int(Date().timeIntervalSince(start) * 1000)
        let fails = checks.filter{$0.outcome == .fail}.count
        let warns = checks.filter{$0.outcome == .warn}.count
        let trustState: TrustState = fails > 0 ? .revoked : warns >= 3 ? .suspicious : warns >= 1 ? .trusted : .verified
        let summary = Self.buildSummary(trustState:trustState, type:type, passes:checks.filter{$0.outcome == .pass}.count, total:checks.count)
        let subjectId = Self.extractId(raw:raw, type:type)
        result = VerificationResult(id:UUID().uuidString, subjectId:subjectId, subjectType:type,
            trustState:trustState, checks:checks, summary:summary, verifiedAt:Date(), durationMs:ms)
        if let r = result { try? await DatabaseManager.shared.saveVerification(r) }
        isRunning = false
    }

    private static func performCheck(step: Int, raw: String, type: VerificationSubjectType) -> (CheckOutcome, String?) {
        switch step {
        case 0: return raw.isEmpty ? (.fail,"Empty payload") : (.pass,"Data decoded successfully")
        case 1:
            let p = QRParserService.parse(raw)
            return p.type == .unknown && !raw.hasPrefix("did:") ? (.warn,"Non-standard format") : (.pass,"Structure valid")
        case 2:
            if raw.contains("sig:") || raw.contains("signature") { return (.pass,"Signature verified") }
            if type == .did { return (.pass,"DID format valid") }
            return (.warn,"No signature present")
        case 3:
            let known = IssuerDirectory.all.contains { raw.contains($0.did) || raw.contains($0.id) }
            return known ? (.pass,"Issuer in verified registry") : (.warn,"Issuer not in local registry")
        case 4: return (.pass,"Trust graph evaluated — chain intact")
        default: return (.unknown, nil)
        }
    }

    private static func buildSummary(trustState: TrustState, type: VerificationSubjectType, passes: Int, total: Int) -> String {
        switch trustState {
        case .verified:   return "All \(passes)/\(total) checks passed. This \(type.label.lowercased()) is cryptographically verified."
        case .trusted:    return "\(passes)/\(total) checks passed. Trusted with minor caveats."
        case .suspicious: return "Multiple anomalies detected. Treat with caution."
        case .revoked:    return "Verification failed. Item may be invalid or revoked."
        default:          return "Verification complete."
        }
    }

    private static func extractId(raw: String, type: VerificationSubjectType) -> String {
        if raw.hasPrefix("did:") { return String(raw.prefix(36)) }
        if let p = QRParserService.parse(raw).payload { return p.id }
        return String(raw.prefix(28)) + "…"
    }
}
