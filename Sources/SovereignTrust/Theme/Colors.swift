import SwiftUI

// MARK: - Hex initialiser
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in:.alphanumerics.inverted)
        var n: UInt64 = 0; Scanner(string:h).scanHexInt64(&n)
        let (a,r,g,b): (UInt64,UInt64,UInt64,UInt64) = h.count == 8
            ? (n>>24,n>>16&0xFF,n>>8&0xFF,n&0xFF)
            : (255,  n>>16,     n>>8&0xFF, n&0xFF)
        self.init(.sRGB, red:Double(r)/255, green:Double(g)/255, blue:Double(b)/255, opacity:Double(a)/255)
    }
}

// MARK: - Static color tokens
extension Color {
    static let stPrimary    = Color.white
    static let stSecondary  = Color.white.opacity(0.65)
    static let stTertiary   = Color.white.opacity(0.40)
    static let stQuaternary = Color.white.opacity(0.22)
    static let stCyan       = Color(hex:"22D3EE")
    static let stBlue       = Color(hex:"3B82F6")
    static let stPurple     = Color(hex:"8B5CF6")
    static let stGreen      = Color(hex:"22C55E")
    static let stGold       = Color(hex:"FFD60A")
    static let stOrange     = Color(hex:"F97316")
    static let stRed        = Color(hex:"FF3355")
    static let stNavy       = Color(red:6/255,green:10/255,blue:34/255)

    // Theme-adaptive helpers
    static func primary(dark: Bool)    -> Color { dark ? .white : Color(hex:"111827") }
    static func secondary(dark: Bool)  -> Color { dark ? Color.white.opacity(0.65) : Color(hex:"4B5563") }
    static func tertiary(dark: Bool)   -> Color { dark ? Color.white.opacity(0.40) : Color(hex:"6B7280") }
}
