import SwiftUI
extension Font {
    static let stDisplay  = Font.largeTitle.bold()
    static let stTitle1   = Font.title.bold()
    static let stTitle2   = Font.title2.bold()
    static let stTitle3   = Font.title3.weight(.semibold)
    static let stHeadline = Font.headline.weight(.semibold)
    static let stBody     = Font.body
    static let stBodySm   = Font.subheadline
    static let stCaption  = Font.caption.weight(.medium)
    static let stLabel    = Font.caption2.weight(.bold)
    static let stMono     = Font.system(.caption, design:.monospaced, weight:.regular)
    static let stMonoSm   = Font.system(.caption2, design:.monospaced, weight:.medium)
}
