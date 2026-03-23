import Foundation
import Observation

enum CredentialFilter: String, CaseIterable {
    case all="All", education="Education", identity="Identity",
         professional="Professional", membership="Membership"
}

@Observable
@MainActor
final class CredentialViewModel {
    var items: [CredentialWithIssuer] = []
    var filtered: [CredentialWithIssuer] = []
    var activeFilter: CredentialFilter = .all
    var isLoading = false
    var selected: CredentialWithIssuer?

    func load(subjectDid: String) async {
        isLoading = true
        let raw: [Credential]
        do { raw = try await DatabaseManager.shared.fetchCredentials(subjectDid:subjectDid) }
        catch { raw = MockData.credentials }
        let src = raw.isEmpty ? MockData.credentials : raw
        items = src.map { c in
            let issuer = IssuerDirectory.find(did:c.issuerDid)
                ?? Issuer(id:"?", did:c.issuerDid, name:"Unknown", shortName:"?",
                          logoEmoji:"❓", category:"unknown", trustState:.unknown, isVerified:false, country:"?")
            return CredentialWithIssuer(credential:c, issuer:issuer)
        }
        applyFilter(activeFilter)
        isLoading = false
    }

    func applyFilter(_ f: CredentialFilter) {
        activeFilter = f
        filtered = f == .all ? items : items.filter {
            $0.credential.type.rawValue.lowercased() == f.rawValue.lowercased()
        }
    }
}
