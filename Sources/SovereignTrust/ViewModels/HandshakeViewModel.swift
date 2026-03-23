import Foundation
import Observation

@Observable
@MainActor
final class HandshakeViewModel {
    var handshake: Handshake?
    var isSigning = false
    var error: String?
    var timeRemaining: Int = 300
    private var timerTask: Task<Void, Never>?
    private let svc = HandshakeService()

    func present(_ h: Handshake) {
        handshake = h
        startCountdown(to: h.challenge.expiresAt)
    }

    func signWithBiometrics() async {
        guard let h = handshake else { return }
        isSigning = true; error = nil
        do {
            let ok = try await BiometricService.shared.authenticate(
                reason: "Sign authentication challenge for \(h.challenge.service)")
            guard ok else { isSigning = false; return }
            svc.processPayload(QRPayload(
                v:1, t:"handshake", id:h.id, did:"", iss:"", hash:"", ts:"",
                service:h.challenge.service, nonce:h.challenge.nonce,
                exp:nil, callback:nil, serial:nil, brand:nil, docType:nil, title:nil))
            let success = await svc.signChallenge()
            handshake = svc.active
            if !success { error = svc.lastError }
        } catch {
            self.error = error.localizedDescription
        }
        isSigning = false
    }

    func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func startCountdown(to date: Date) {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                let rem = max(0, Int(date.timeIntervalSinceNow))
                self.timeRemaining = rem
                if rem == 0 { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}
