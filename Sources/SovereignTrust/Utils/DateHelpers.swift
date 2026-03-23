import Foundation
extension Date {
    var isExpired: Bool   { self < Date() }
    var isExpiringSoon: Bool { self < Date(timeIntervalSinceNow: 86400*30) && !isExpired }
    func daysUntil() -> Int { max(0, Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0) }
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let f = DateFormatter(); f.dateStyle = style; return f.string(from: self)
    }
}
