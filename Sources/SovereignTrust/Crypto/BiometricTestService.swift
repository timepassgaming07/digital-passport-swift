import Foundation
import LocalAuthentication

struct BiometricTestResult {
    let success: Bool
    let biometryType: BiometryType
    let errorMessage: String?
    let testedAt: Date
}

actor BiometricTestService {
    static let shared = BiometricTestService()
    private init() {}

    func runTest() async -> BiometricTestResult {
        let ctx = LAContext()
        var nsErr: NSError?
        let available = ctx.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &nsErr)

        let type: BiometryType = switch ctx.biometryType {
            case .faceID:  .faceID
            case .touchID: .touchID
            default:       .none
        }
        guard available else {
            return BiometricTestResult(success:false, biometryType:type,
                errorMessage:nsErr?.localizedDescription ?? "Not available", testedAt:Date())
        }
        do {
            let ok = try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Testing biometric authentication")
            return BiometricTestResult(success:ok, biometryType:type,
                                       errorMessage:nil, testedAt:Date())
        } catch {
            return BiometricTestResult(success:false, biometryType:type,
                                       errorMessage:error.localizedDescription, testedAt:Date())
        }
    }
}
