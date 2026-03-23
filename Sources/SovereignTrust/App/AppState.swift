import SwiftUI
import Observation

@Observable
final class AppState {
    static let shared = AppState()
    var isDarkMode: Bool = true
    private init() {}
}
