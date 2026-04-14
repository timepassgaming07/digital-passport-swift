import Foundation
import Observation

// MARK: – Trust Score ViewModel (Hook equivalent)

/// Non-blocking, memoised trust score evaluation.
/// Use from any SwiftUI view — calls are dispatched off main thread.
@Observable
@MainActor
final class TrustScoreViewModel {

    // MARK: – Published State

    private(set) var score: TrustScore?
    private(set) var isEvaluating = false

    // MARK: – Memoisation Cache

    /// Prevents redundant evaluations for the same subject.
    private var lastEvaluatedId: String?

    // MARK: – Evaluate Verification Result

    /// Evaluate a verification result + its raw payload.
    /// Non-blocking — dispatches to TrustScoreService actor.
    func evaluate(result: VerificationResult, rawPayload: String,
                  credential: Credential? = nil, issuer: Issuer? = nil) {
        let subjectKey = "\(result.id)-\(rawPayload.hashValue)"
        guard subjectKey != lastEvaluatedId else { return }

        isEvaluating = true
        lastEvaluatedId = subjectKey

        Task {
            let s = await TrustScoreService.shared.evaluate(
                result: result, rawPayload: rawPayload,
                credential: credential, issuer: issuer
            )
            self.score = s
            self.isEvaluating = false
        }
    }

    // MARK: – Evaluate Credential

    /// Evaluate a standalone credential's trust score.
    func evaluateCredential(_ credential: Credential, issuer: Issuer?) {
        let key = "cred-\(credential.id)"
        guard key != lastEvaluatedId else { return }

        isEvaluating = true
        lastEvaluatedId = key

        Task {
            let s = await TrustScoreService.shared.evaluateCredential(credential, issuer: issuer)
            self.score = s
            self.isEvaluating = false
        }
    }

    // MARK: – Reset

    func reset() {
        score = nil
        lastEvaluatedId = nil
        isEvaluating = false
    }
}
