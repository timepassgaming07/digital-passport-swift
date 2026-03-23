import Foundation
import Observation

enum FeedFilter: String, CaseIterable {
    case all = "All"
    case verified   = "Verified"
    case suspicious = "Suspicious"
    case unverified = "Unverified"
}

@Observable
@MainActor
final class TruthFeedViewModel {
    var posts: [Post] = []
    var filtered: [Post] = []
    var filter: FeedFilter = .all
    var isLoading = false

    func load() async {
        isLoading = true
        try? await Task.sleep(nanoseconds:400_000_000)
        var enriched = MockData.posts
        for i in enriched.indices {
            if enriched[i].fraudAnalysis == nil {
                enriched[i].fraudAnalysis = FraudSignalService.analyse(enriched[i])
            }
        }
        posts = enriched
        applyFilter(filter)
        isLoading = false
    }

    func applyFilter(_ f: FeedFilter) {
        filter = f
        filtered = switch f {
        case .all:        posts
        case .verified:   posts.filter { $0.trustState == .verified }
        case .suspicious: posts.filter { $0.trustState == .suspicious || $0.trustState == .revoked }
        case .unverified: posts.filter { $0.trustState == .unknown || $0.trustState == .pending }
        }
    }

    func count(_ f: FeedFilter) -> Int {
        switch f {
        case .all:        return posts.count
        case .verified:   return posts.filter{$0.trustState == .verified}.count
        case .suspicious: return posts.filter{$0.trustState == .suspicious || $0.trustState == .revoked}.count
        case .unverified: return posts.filter{$0.trustState == .unknown || $0.trustState == .pending}.count
        }
    }
}
