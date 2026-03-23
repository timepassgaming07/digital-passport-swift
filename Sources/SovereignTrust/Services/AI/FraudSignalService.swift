import Foundation

enum FraudSignalService {
    // Evaluates a post and returns fraud analysis
    static func analyse(_ post: Post) -> FraudAnalysis {
        var signals: [FraudSignal] = []
        var risk = 0

        if !post.author.isVerified {
            signals.append(FraudSignal(id:.unverifiedAuthor, label:"Unverified Author",
                severity:.medium, detail:"Author DID not in trusted registry",
                remediation:"Check author credentials before sharing"))
            risk += 25
        }
        if post.author.institution == nil {
            signals.append(FraudSignal(id:.noInstitution, label:"No Institutional Affiliation",
                severity:.low, detail:"Author has no verified institution",
                remediation:nil))
            risk += 10
        }
        if post.sourceUrl == nil {
            signals.append(FraudSignal(id:.noSource, label:"No Source URL",
                severity:.high, detail:"Post lacks a verifiable source link",
                remediation:"Always verify claims with primary sources"))
            risk += 35
        }
        if post.claimRatio < 0.3 && post.claimCount > 0 {
            signals.append(FraudSignal(id:.unverifiedClaims, label:"Unverified Claims",
                severity:.high, detail:"\(post.claimCount - post.verifiedClaimCount) claims lack verification",
                remediation:"Cross-reference with official sources"))
            risk += 30
        }
        let state: TrustState = risk > 60 ? .suspicious : risk > 30 ? .trusted : .verified
        return FraudAnalysis(trustState:state, signals:signals, riskScore:min(100,risk), analysedAt:Date())
    }
}
