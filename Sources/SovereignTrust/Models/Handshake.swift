import Foundation
enum HandshakeStatus: String, Codable { case pending, signed, verified, expired, rejected }
struct HandshakeChallenge: Identifiable, Codable {
    let id: String; let service: String; let nonce: String
    let callbackUrl: String; let expiresAt: Date
}
struct Handshake: Identifiable, Codable {
    let id: String; let challenge: HandshakeChallenge
    var status: HandshakeStatus; let createdAt: Date; var signedAt: Date?
}
