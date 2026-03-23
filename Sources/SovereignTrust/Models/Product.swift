import Foundation

enum ProductStatus: String, Codable, Hashable {
    case authentic, counterfeit, unverified, recalled
}

struct CustodyCheckpoint: Identifiable, Codable, Hashable {
    let id: String; let location: String; let actor: String
    let timestamp: Date; let note: String?
}

struct Product: Identifiable, Codable, Hashable {
    let id: String; let name: String; let brand: String
    let serialNumber: String; let manufacturerDid: String
    let status: ProductStatus; let trustState: TrustState
    let custodyChain: [CustodyCheckpoint]; let manufacturedAt: Date
    let description: String; let category: String
    var statusIcon: String {
        switch status {
        case .authentic:   return "checkmark.seal.fill"
        case .counterfeit: return "xmark.seal.fill"
        case .unverified:  return "questionmark.circle.fill"
        case .recalled:    return "exclamationmark.triangle.fill"
        }
    }
}
