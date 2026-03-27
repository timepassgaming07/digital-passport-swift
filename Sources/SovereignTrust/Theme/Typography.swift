import SwiftUI

// MARK: – Sovereign Trust Typography System (Rounded + Tracked)
extension Font {
    // Display — hero headers, splash screen
    static let stDisplay  = Font.system(.largeTitle, design:.rounded, weight:.bold)
    // Titles — section headers
    static let stTitle1   = Font.system(.title,  design:.rounded, weight:.bold)
    static let stTitle2   = Font.system(.title2, design:.rounded, weight:.bold)
    static let stTitle3   = Font.system(.title3, design:.rounded, weight:.semibold)
    // Headline — card titles, row headers
    static let stHeadline = Font.system(.headline, design:.rounded, weight:.semibold)
    // Body
    static let stBody     = Font.system(.body, design:.rounded, weight:.regular)
    static let stBodySm   = Font.system(.subheadline, design:.rounded, weight:.regular)
    // Captions & labels
    static let stCaption  = Font.system(.caption, design:.rounded, weight:.medium)
    static let stLabel    = Font.system(.caption2, design:.rounded, weight:.bold)
    // Monospaced — hashes, IDs, codes
    static let stMono     = Font.system(.caption, design:.monospaced, weight:.regular)
    static let stMonoSm   = Font.system(.caption2, design:.monospaced, weight:.medium)
}

// MARK: – Tracking (letter-spacing) helpers
extension View {
    /// Loose tracking for display / title text
    func stTracked(_ value: CGFloat = 0.4) -> some View {
        self.tracking(value)
    }
    /// Wider tracking for labels / all-caps
    func stWideTracked() -> some View {
        self.tracking(1.2)
    }
}
