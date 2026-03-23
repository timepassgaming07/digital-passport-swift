import Foundation
import SwiftUI
enum TrustNodeType: String, Codable {
    case issuer, holder, verifier, credential, product, institution, wallet
    var icon: String {
        switch self {
        case .issuer:      return "🏛️"
        case .holder:      return "👛"
        case .verifier:    return "🔍"
        case .credential:  return "📄"
        case .product:     return "📦"
        case .institution: return "🏢"
        case .wallet:      return "💎"
        }
    }
}
enum TrustEdgeType: String, Codable { case issues, holds, verifies, delegates, anchors, trusts }
enum TrustEdgeStrength: String, Codable { case strong, moderate, weak }
struct TrustNode: Identifiable, Codable {
    let id: String; let label: String; let sublabel: String?
    let type: TrustNodeType; let did: String?
    let trustState: TrustState; let emoji: String; let verified: Bool
    var position: CGPoint = .zero
    enum CodingKeys: String, CodingKey {
        case id,label,sublabel,type,did,trustState,emoji,verified
    }
}
struct TrustEdge: Identifiable, Codable {
    let id: String; let fromId: String; let toId: String
    let edgeType: TrustEdgeType; let strength: TrustEdgeStrength; let label: String?
}
struct TrustScoreResult: Codable {
    let score: Int; let label: String; let trustState: TrustState
    let nodeCount: Int; let edgeCount: Int
}
struct TrustGraph: Identifiable, Codable {
    let id: String; let title: String
    let nodes: [TrustNode]; let edges: [TrustEdge]; let score: TrustScoreResult
}
