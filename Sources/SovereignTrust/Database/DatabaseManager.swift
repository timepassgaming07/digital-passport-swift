import Foundation

actor DatabaseManager {
    static let shared = DatabaseManager()
    private init() {}
    private var verifications: [VerificationResult] = []

    func setup() async throws {}

    func fetchCredentials(subjectDid: String) async throws -> [Credential] {
        MockData.credentials.filter { $0.subjectDid == subjectDid }
    }

    func saveVerification(_ result: VerificationResult) async throws {
        verifications.insert(result, at: 0)
        if verifications.count > 50 { verifications = Array(verifications.prefix(50)) }
    }

    func recentVerifications(limit: Int = 8) async throws -> [VerificationResult] {
        Array(verifications.prefix(limit))
    }
}
