import Foundation
struct QRPayload: Codable {
    let v: Int; let t: String; let id: String
    let did: String; let iss: String; let hash: String; let ts: String
    let service: String?; let nonce: String?; let exp: Int?
    let callback: String?; let serial: String?; let brand: String?
    let docType: String?; let title: String?
}
