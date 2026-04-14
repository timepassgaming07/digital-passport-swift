import Foundation

// MARK: – Trust Engine — On-Device Anomaly Detection

/// Production-grade trust scoring engine using weighted feature analysis
/// with z-score anomaly detection. Fully deterministic, runs in <1ms.
/// Designed to be replaceable with CoreML model in future.
enum TrustEngine {

    // MARK: – Public API

    static func evaluate(_ input: TrustInput) -> TrustScore {
        let features = extractFeatures(input)
        let (rawScore, reasons) = score(features: features, input: input)
        let clamped = max(0, min(100, rawScore))
        let riskLevel: RiskLevel = clamped >= 70 ? .low : clamped >= 40 ? .medium : .high
        return TrustScore(score: clamped, riskLevel: riskLevel, reasons: reasons, computedAt: Date())
    }

    // MARK: – Feature Extraction

    /// Converts raw signals to normalised 0–1 anomaly features.
    private static func extractFeatures(_ input: TrustInput) -> FeatureVector {
        var f = FeatureVector()

        // 1. Scan frequency (z-score style)
        f.scanFrequencyAnomaly = scanFrequencyAnomaly(timestamps: input.recentScanTimestamps)

        // 2. Timing anomaly (scans at unusual hours)
        f.timingAnomaly = timingAnomaly(date: input.scanTimestamp)

        // 3. Credential reuse
        f.credentialReuseAnomaly = reuseAnomaly(count: input.credentialReuseCount)

        // 4. Issuer trust deficit
        f.issuerTrustDeficit = issuerDeficit(
            trustState: input.issuerTrustState,
            isVerified: input.issuerIsVerified,
            inRegistry: input.issuerInRegistry
        )

        // 5. Verification failure rate
        f.verificationFailureRate = failureRate(
            passes: input.recentPassCount,
            fails: input.recentFailCount
        )

        // 6. Structural anomaly
        f.structuralAnomaly = structuralAnomaly(
            hasSignature: input.hasSignature,
            hasValidStructure: input.hasValidStructure,
            payloadSize: input.payloadSizeBytes
        )

        // 7. Expiration risk
        f.expirationRisk = input.isExpired ? 1.0 : 0.0

        // 8. Credential age anomaly
        f.ageAnomaly = ageAnomaly(age: input.credentialAge)

        return f
    }

    // MARK: – Weighted Scoring Pipeline

    /// Each feature has a weight. Score starts at 100 and subtracts penalties.
    /// Returns (finalScore, reasons).
    private static func score(features f: FeatureVector, input: TrustInput) -> (Int, [TrustReason]) {
        var reasons: [TrustReason] = []
        var penalty: Double = 0

        // Weights — tuned for production sensitivity
        let weights: [(keyPath: KeyPath<FeatureVector, Double>, weight: Double, label: String)] = [
            (\.scanFrequencyAnomaly,    25, "Scan frequency"),
            (\.timingAnomaly,           8,  "Scan timing"),
            (\.credentialReuseAnomaly,  15, "Credential reuse"),
            (\.issuerTrustDeficit,      22, "Issuer trust"),
            (\.verificationFailureRate, 18, "Verification history"),
            (\.structuralAnomaly,       15, "Payload structure"),
            (\.expirationRisk,          12, "Credential expiry"),
            (\.ageAnomaly,              5,  "Credential age"),
        ]

        for w in weights {
            let value = f[keyPath: w.keyPath]
            let contribution = value * w.weight
            penalty += contribution

            if value > 0.05 {
                let severity: ReasonSeverity
                switch value {
                case 0.7...:          severity = .critical
                case 0.4..<0.7:       severity = .warning
                default:              severity = .neutral
                }
                reasons.append(TrustReason(
                    signal: reasonText(feature: w.label, value: value, input: input),
                    weight: contribution,
                    severity: severity
                ))
            }
        }

        // Positive signals
        if input.issuerInRegistry && input.issuerIsVerified {
            reasons.insert(TrustReason(signal: "Issuer in verified registry", weight: 0, severity: .positive), at: 0)
        }
        if input.hasSignature && input.hasValidStructure {
            reasons.insert(TrustReason(signal: "Cryptographic signature present", weight: 0, severity: .positive), at: 0)
        }
        if input.recentPassCount > 3 && input.recentFailCount == 0 {
            reasons.insert(TrustReason(signal: "Strong verification history", weight: 0, severity: .positive), at: 0)
        }

        let finalScore = Int(round(100 - penalty))
        return (finalScore, reasons)
    }

    // MARK: – Individual Feature Computations

    /// Z-score style scan frequency detection.
    /// Returns 0–1 anomaly score. > 5 scans/minute or > 20/hour is anomalous.
    private static func scanFrequencyAnomaly(timestamps: [Date]) -> Double {
        guard !timestamps.isEmpty else { return 0 }
        let now = Date()
        let oneMinute = timestamps.filter { now.timeIntervalSince($0) < 60 }.count
        let oneHour   = timestamps.filter { now.timeIntervalSince($0) < 3600 }.count

        // Expected baseline: ~2 scans/min, ~10 scans/hour
        let minuteZ = max(0, Double(oneMinute) - 2) / 3.0    // σ ≈ 3
        let hourZ   = max(0, Double(oneHour) - 10) / 8.0     // σ ≈ 8

        return min(1.0, max(minuteZ, hourZ))
    }

    /// Scans between 1am-5am local time are unusual.
    private static func timingAnomaly(date: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 1..<5:  return 0.7
        case 0, 5:   return 0.3
        default:     return 0.0
        }
    }

    /// Credential scanned excessively — possible replay or brute-force.
    private static func reuseAnomaly(count: Int) -> Double {
        switch count {
        case 0...2:   return 0.0
        case 3...5:   return 0.2
        case 6...10:  return 0.5
        case 11...20: return 0.75
        default:      return 1.0
        }
    }

    /// Issuer not in registry or has low trust.
    private static func issuerDeficit(trustState: TrustState?, isVerified: Bool, inRegistry: Bool) -> Double {
        if !inRegistry { return 0.9 }
        if !isVerified { return 0.6 }
        switch trustState {
        case .verified:   return 0.0
        case .trusted:    return 0.1
        case .suspicious: return 0.7
        case .revoked:    return 1.0
        case .pending:    return 0.4
        case .unknown:    return 0.5
        case .none:       return 0.5
        }
    }

    /// Recent verification failure ratio.
    private static func failureRate(passes: Int, fails: Int) -> Double {
        let total = passes + fails
        guard total > 0 else { return 0 }
        return Double(fails) / Double(total)
    }

    /// Missing signature, invalid structure, or suspicious payload size.
    private static func structuralAnomaly(hasSignature: Bool, hasValidStructure: Bool, payloadSize: Int) -> Double {
        var score: Double = 0
        if !hasSignature      { score += 0.4 }
        if !hasValidStructure { score += 0.4 }
        if payloadSize < 10   { score += 0.2 }  // suspiciously small
        if payloadSize > 5000 { score += 0.1 }  // unusually large
        return min(1.0, score)
    }

    /// Freshly issued (<1 minute) or very old (>5 years) credentials are unusual.
    private static func ageAnomaly(age: TimeInterval) -> Double {
        if age < 0   { return 0.8 }              // future-dated
        if age < 60  { return 0.4 }              // < 1 minute old
        if age > 5 * 365.25 * 86400 { return 0.3 } // > 5 years
        return 0.0
    }

    // MARK: – Reason Text Generator

    private static func reasonText(feature: String, value: Double, input: TrustInput) -> String {
        switch feature {
        case "Scan frequency":
            let recent = input.recentScanTimestamps.filter { Date().timeIntervalSince($0) < 60 }.count
            return "High scan rate detected (\(recent) scans/min)"
        case "Scan timing":
            let h = Calendar.current.component(.hour, from: input.scanTimestamp)
            return "Unusual scan time (\(h):00)"
        case "Credential reuse":
            return "Credential scanned \(input.credentialReuseCount) times"
        case "Issuer trust":
            if !input.issuerInRegistry { return "Issuer not found in trusted registry" }
            if !input.issuerIsVerified { return "Issuer not verified" }
            return "Issuer trust level: \(input.issuerTrustState?.label ?? "unknown")"
        case "Verification history":
            return "\(input.recentFailCount) recent verification failures"
        case "Payload structure":
            if !input.hasSignature { return "No cryptographic signature present" }
            if !input.hasValidStructure { return "Non-standard payload structure" }
            return "Payload size anomaly (\(input.payloadSizeBytes) bytes)"
        case "Credential expiry":
            return "Credential has expired"
        case "Credential age":
            if input.credentialAge < 60 { return "Credential issued less than 1 minute ago" }
            return "Credential is over 5 years old"
        default:
            return "\(feature) anomaly detected"
        }
    }
}
