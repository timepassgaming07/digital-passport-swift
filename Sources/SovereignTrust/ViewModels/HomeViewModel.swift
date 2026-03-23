import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var identity: Identity = .mock
    var credentials: [CredentialWithIssuer] = []
    var recentVerifications: [VerificationResult] = []
    var isLoading = false

    func load() async {
        isLoading = true
        do {
            let raw = try await DatabaseManager.shared.fetchCredentials(subjectDid: identity.did)
            let isEmpty = raw.isEmpty
            let creds = isEmpty ? MockData.credentials : raw
            credentials = creds.map { c in
                let issuer = IssuerDirectory.find(did:c.issuerDid)
                    ?? Issuer(id:"?", did:c.issuerDid, name:"Unknown Issuer", shortName:"Unknown",
                              logoEmoji:"❓", category:"unknown", trustState:.unknown,
                              isVerified:false, country:"?")
                return CredentialWithIssuer(credential:c, issuer:issuer)
            }
            recentVerifications = (try? await DatabaseManager.shared.recentVerifications()) ?? []
        } catch {
            credentials = MockData.credentials.map { c in
                CredentialWithIssuer(credential:c, issuer:IssuerDirectory.find(did:c.issuerDid)
                    ?? Issuer(id:"?", did:c.issuerDid, name:"Unknown", shortName:"?",
                              logoEmoji:"❓", category:"unknown", trustState:.unknown, isVerified:false, country:"?"))
            }
        }
        isLoading = false
    }
}
