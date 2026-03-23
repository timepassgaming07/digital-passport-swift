import SwiftUI

enum TrustState: String, Codable, CaseIterable, Hashable {
    case verified, trusted, suspicious, revoked, pending, unknown
    var glowColor: Color {
        switch self {
        case .verified:   return Color(hex:"00FF88")
        case .trusted:    return Color(hex:"3B82F6")
        case .suspicious: return Color(hex:"F97316")
        case .revoked:    return Color(hex:"FF3355")
        case .pending:    return Color(hex:"FFD60A")
        case .unknown:    return Color(hex:"8E8E93")
        }
    }
    var glowOpacity: Double {
        switch self {
        case .verified,.trusted:        return 0.35
        case .suspicious,.revoked:      return 0.48
        case .pending:                  return 0.30
        case .unknown:                  return 0.15
        }
    }
    var label: String { rawValue.capitalized }
    var sfIcon: String {
        switch self {
        case .verified:   return "checkmark.seal.fill"
        case .trusted:    return "shield.checkered"
        case .suspicious: return "exclamationmark.triangle.fill"
        case .revoked:    return "xmark.seal.fill"
        case .pending:    return "clock.fill"
        case .unknown:    return "questionmark.circle"
        }
    }
}
