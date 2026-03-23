import Foundation
enum AppRoute: Hashable {
    case home, scan, passport, verify, feed, settings
    case credentialDetail(String)
    case productDetail(String)
    case handshake(String)
}
