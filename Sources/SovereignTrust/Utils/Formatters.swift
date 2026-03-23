import Foundation
struct Formatters {
    static let shortDate: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    static let relativeTime: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()
    static func timeAgo(_ date: Date) -> String {
        relativeTime.localizedString(for: date, relativeTo: Date())
    }
    static func shortDID(_ did: String) -> String {
        guard did.count > 24 else { return did }
        return String(did.prefix(20)) + "…" + String(did.suffix(6))
    }
    static func shortHash(_ hash: String) -> String {
        guard hash.count > 16 else { return hash }
        return String(hash.prefix(8)) + "…" + String(hash.suffix(8))
    }
}
