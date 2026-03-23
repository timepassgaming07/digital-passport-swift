import Foundation

enum BiometryType: String, Codable {
    case faceID  = "Face ID"
    case touchID = "Touch ID"
    case none    = "None"
}

struct Identity: Codable, Equatable {
    let did: String
    let displayName: String
    let handle: String
    let avatarEmoji: String
    let trustScore: Int
    let trustState: TrustState
    let hardwareKeyId: String
    let biometryType: BiometryType
    let createdAt: Date
    let lastVerifiedAt: Date?

    static let mock = Identity(
        did: "did:sov:7Tq3kTmNpL8vXoAe9fP2Yz",
        displayName: "Aksh Jain",
        handle: "@akshjain.sov",
        avatarEmoji: "🔐",
        trustScore: 94,
        trustState: .verified,
        hardwareKeyId: "SE-KEY-A1B2C3",
        biometryType: .faceID,
        createdAt: Date(timeIntervalSinceNow: -86400 * 90),
        lastVerifiedAt: Date(timeIntervalSinceNow: -3600)
    )
}
