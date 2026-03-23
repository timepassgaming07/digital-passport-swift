import Foundation
import LocalAuthentication

enum BiometricError: LocalizedError {
    case notAvailable(String)
    case denied
    case failed(String)
    var errorDescription: String? {
        switch self {
        case .notAvailable(let m): return "Biometrics not available: \(m)"
        case .denied:              return "Biometric access denied"
        case .failed(let m):       return "Authentication failed: \(m)"
        }
    }
}

// RULE: Only call authenticate() from an explicit user button tap
actor BiometricService {
    static let shared = BiometricService()
    private init() {}

    func authenticate(reason: String) async throws -> Bool {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error:&err) else {
            throw BiometricError.notAvailable(err?.localizedDescription ?? "unavailable")
        }
        do {
            return try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch let e as LAError {
            if e.code == .userCancel { return false }
            throw BiometricError.failed(e.localizedDescription)
        }
    }

    nonisolated func biometryType() -> BiometryType {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error:nil)
        return switch ctx.biometryType {
            case .faceID:  .faceID
            case .touchID: .touchID
            default:       .none
        }
    }

    nonisolated func isAvailable() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
}
