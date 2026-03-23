import Foundation
import Observation

@Observable
final class HandshakeService {
    var active: Handshake?
    var isProcessing = false
    var lastError: String?

    func processPayload(_ p: QRPayload) {
        guard let nonce = p.nonce, let service = p.service else { return }
        let exp = p.exp.map { Date(timeIntervalSince1970:TimeInterval($0)) }
                  ?? Date(timeIntervalSinceNow:300)
        let challenge = HandshakeChallenge(id:UUID().uuidString, service:service,
            nonce:nonce, callbackUrl:p.callback ?? "", expiresAt:exp)
        active = Handshake(id:UUID().uuidString, challenge:challenge,
                           status:.pending, createdAt:Date(), signedAt:nil)
    }

    func signChallenge() async -> Bool {
        guard let h = active else { return false }
        isProcessing = true; lastError = nil
        do {
            guard let nonceData = h.challenge.nonce.data(using:.utf8) else {
                throw SecureEnclaveError.signFailed
            }
            // await because SecureEnclaveService is an actor
            _ = try await SecureEnclaveService.shared.sign(payload: nonceData)
            active = Handshake(id:h.id, challenge:h.challenge,
                               status:.verified, createdAt:h.createdAt, signedAt:Date())
            isProcessing = false
            return true
        } catch {
            lastError = error.localizedDescription
            active = Handshake(id:h.id, challenge:h.challenge,
                               status:.rejected, createdAt:h.createdAt, signedAt:nil)
            isProcessing = false
            return false
        }
    }

    func dismiss() { active = nil; lastError = nil }
}
