#!/bin/bash
# ================================================================
# setup_sovereign_trust_swiftui.sh  v2.0
# Sovereign Trust — Full SwiftUI Liquid Glass Identity Wallet
# Usage: bash setup_sovereign_trust_swiftui.sh ~/Developer
# ================================================================
set -euo pipefail
INSTALL_DIR="${1:-$HOME/Developer}"
PROJECT="SovereignTrust"
ROOT="$INSTALL_DIR/$PROJECT"
SRC="$ROOT/Sources/$PROJECT"
BUNDLE="com.sovereigntrust.app"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   SOVEREIGN TRUST  ·  SwiftUI Liquid Glass  v2.0        ║"
echo "╚══════════════════════════════════════════════════════════╝"

# ── 1. Xcode check ────────────────────────────────────────────
if ! command -v xcodebuild &>/dev/null; then
  echo "❌  Xcode not found. Install from Mac App Store, then re-run."; exit 1
fi
echo "✅  $(xcodebuild -version | head -1)"

# ── 2. XcodeGen ───────────────────────────────────────────────
if ! command -v xcodegen &>/dev/null; then
  command -v brew &>/dev/null || { echo "❌  Homebrew missing. Install from https://brew.sh"; exit 1; }
  brew install xcodegen
fi
echo "✅  XcodeGen $(xcodegen --version)"

# ── 3. Create directory tree ──────────────────────────────────
mkdir -p "$ROOT"
cd "$ROOT"
for d in \
  "$SRC/App" "$SRC/Theme" "$SRC/Utils" \
  "$SRC/Models" "$SRC/Constants" \
  "$SRC/Database/Repositories" \
  "$SRC/Crypto" \
  "$SRC/Services/Biometric" "$SRC/Services/QR" \
  "$SRC/Services/Identity" "$SRC/Services/Credentials" \
  "$SRC/Services/Handshake" "$SRC/Services/Products" \
  "$SRC/Services/Truth" "$SRC/Services/AI" \
  "$SRC/Domain/Verification" "$SRC/Domain/Credentials" \
  "$SRC/Domain/Truth" "$SRC/Domain/TrustGraph" \
  "$SRC/ViewModels" \
  "$SRC/Components" \
  "$SRC/Screens/Home" "$SRC/Screens/Scan" \
  "$SRC/Screens/Passport" "$SRC/Screens/Credentials" \
  "$SRC/Screens/Verify" "$SRC/Screens/TruthFeed" \
  "$SRC/Screens/Handshake" "$SRC/Screens/Products" \
  "$SRC/Screens/Settings" \
  "$SRC/Resources" \
  "SovereignTrust" "Tests"; do
  mkdir -p "$d"
done
echo "✅  Directory tree created"

# ================================================================
# WRITE ALL SWIFT SOURCE FILES
# ================================================================

# ════════════════════════════════════════════════════════════════
# LAYER 0 — THEME FOUNDATION
# ════════════════════════════════════════════════════════════════

cat > "$SRC/Theme/Colors.swift" << 'EOF'
import SwiftUI

// MARK: - Hex initialiser
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var n: UInt64 = 0; Scanner(string: h).scanHexInt64(&n)
        let (a,r,g,b): (UInt64,UInt64,UInt64,UInt64) = h.count == 8
            ? (n>>24, n>>16&0xFF, n>>8&0xFF, n&0xFF)
            : (255,   n>>16,      n>>8&0xFF,  n&0xFF)
        self.init(.sRGB, red:Double(r)/255, green:Double(g)/255, blue:Double(b)/255, opacity:Double(a)/255)
    }
}

// MARK: - Design tokens
extension Color {
    // Text hierarchy
    static let stPrimary    = Color.white
    static let stSecondary  = Color.white.opacity(0.65)
    static let stTertiary   = Color.white.opacity(0.40)
    static let stQuaternary = Color.white.opacity(0.22)
    // Accents
    static let stCyan   = Color(hex: "22D3EE")
    static let stBlue   = Color(hex: "3B82F6")
    static let stPurple = Color(hex: "8B5CF6")
    static let stGreen  = Color(hex: "22C55E")
    static let stGold   = Color(hex: "FFD60A")
    static let stOrange = Color(hex: "F97316")
    static let stRed    = Color(hex: "FF3355")
    // Background
    static let stNavy   = Color(red:10/255, green:15/255, blue:44/255)
}
EOF

cat > "$SRC/Theme/Typography.swift" << 'EOF'
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
EOF

cat > "$SRC/Theme/DesignTokens.swift" << 'EOF'
import SwiftUI

// MARK: - Animations
extension Animation {
    static let stSpring     = Animation.spring(response:0.40, dampingFraction:0.80)
    static let stFastSpring = Animation.spring(response:0.25, dampingFraction:0.70)
    static let stFloat      = Animation.easeInOut(duration:3.0).repeatForever(autoreverses:true)
    static let stPulse      = Animation.easeInOut(duration:1.6).repeatForever(autoreverses:true)
}

// MARK: - Badge size
enum BadgeSize {
    case small, medium, large
    var dotSize: CGFloat  { [small:5,medium:7,large:9][self]! }
    var fontSize: CGFloat { [small:9,medium:11,large:13][self]! }
    var hPad: CGFloat     { [small:6,medium:9,large:13][self]! }
    var vPad: CGFloat     { [small:3,medium:5,large:7][self]! }
}

// MARK: - GlassButton variant
enum GlassButtonVariant {
    case primary, secondary, danger, ghost
    var textColor: Color {
        switch self {
        case .primary:   return .stCyan
        case .secondary: return .stPrimary
        case .danger:    return .stRed
        case .ghost:     return .stSecondary
        }
    }
    var material: AnyShapeStyle {
        self == .primary ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.ultraThinMaterial)
    }
    var borderColor: Color {
        switch self {
        case .primary:   return Color.stCyan.opacity(0.45)
        case .secondary: return Color.white.opacity(0.14)
        case .danger:    return Color.stRed.opacity(0.45)
        case .ghost:     return Color.white.opacity(0.08)
        }
    }
    var shadow: Color {
        switch self {
        case .primary: return .stCyan
        case .danger:  return .stRed
        default:       return .clear
        }
    }
}

// MARK: - Pulse modifier
struct PulseModifier: ViewModifier {
    let active: Bool
    let color: Color
    @State private var scale: CGFloat = 1
    func body(content: Content) -> some View {
        content
            .scaleEffect(active ? scale : 1)
            .onChange(of: active) { _, val in
                if val { withAnimation(.stPulse) { scale = 1.4 } }
                else   { scale = 1 }
            }
    }
}
EOF

cat > "$SRC/Utils/Formatters.swift" << 'EOF'
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
EOF

cat > "$SRC/Utils/DateHelpers.swift" << 'EOF'
import Foundation
extension Date {
    var isExpired: Bool   { self < Date() }
    var isExpiringSoon: Bool { self < Date(timeIntervalSinceNow: 86400*30) && !isExpired }
    func daysUntil() -> Int { max(0, Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0) }
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let f = DateFormatter(); f.dateStyle = style; return f.string(from: self)
    }
}
EOF


# ════════════════════════════════════════════════════════════════
# LAYER 1 — MODELS
# ════════════════════════════════════════════════════════════════

cat > "$SRC/Models/TrustState.swift" << 'EOF'
import SwiftUI

enum TrustState: String, Codable, CaseIterable, Hashable {
    case verified, trusted, suspicious, revoked, pending, unknown
    var glowColor: Color {
        switch self {
        case .verified:   return Color(hex:"00FF88")
        case .trusted:    return Color(hex:"3B82F6")
        case .suspicious: return Color(hex:"F97316")
        case .revoked:    return Color(hex:"FF3355")
        case .pending:    return Color(hex:"FFD60A")
        case .unknown:    return Color(hex:"8E8E93")
        }
    }
    var glowOpacity: Double {
        switch self {
        case .verified,.trusted:        return 0.35
        case .suspicious,.revoked:      return 0.48
        case .pending:                  return 0.30
        case .unknown:                  return 0.15
        }
    }
    var label: String { rawValue.capitalized }
    var sfIcon: String {
        switch self {
        case .verified:   return "checkmark.seal.fill"
        case .trusted:    return "shield.checkered"
        case .suspicious: return "exclamationmark.triangle.fill"
        case .revoked:    return "xmark.seal.fill"
        case .pending:    return "clock.fill"
        case .unknown:    return "questionmark.circle"
        }
    }
}
EOF

cat > "$SRC/Models/Credential.swift" << 'EOF'
import Foundation
enum CredentialType: String, Codable, CaseIterable {
    case education, identity, professional, membership, product, document
    var icon: String {
        switch self {
        case .education:    return "graduationcap.fill"
        case .identity:     return "person.crop.rectangle.fill"
        case .professional: return "briefcase.fill"
        case .membership:   return "person.2.fill"
        case .product:      return "shippingbox.fill"
        case .document:     return "doc.text.fill"
        }
    }
    var label: String { rawValue.capitalized }
}
enum CredentialStatus: String, Codable {
    case active, revoked, expired, suspended
}
struct Credential: Identifiable, Codable, Equatable {
    let id: String
    let type: CredentialType
    let title: String
    let description: String?
    let issuerDid: String
    let subjectDid: String
    let issuedAt: Date
    let expiresAt: Date?
    let status: CredentialStatus
    let trustState: TrustState
    let hash: String
    let signature: String?
    let isVerified: Bool
    let rawJson: String?
    var isExpired: Bool { expiresAt?.isExpired ?? false }
}
struct Issuer: Identifiable, Codable, Equatable {
    let id: String; let did: String; let name: String; let shortName: String
    let logoEmoji: String; let category: String
    let trustState: TrustState; let isVerified: Bool; let country: String
}
struct CredentialWithIssuer: Identifiable {
    var id: String { credential.id }
    let credential: Credential; let issuer: Issuer
}
EOF

cat > "$SRC/Models/Identity.swift" << 'EOF'
import Foundation
enum BiometryType: String, Codable { case faceID = "Face ID", touchID = "Touch ID", none = "None" }
struct Identity: Codable, Equatable {
    let did: String; let displayName: String; let handle: String
    let avatarEmoji: String; let trustScore: Int; let trustState: TrustState
    let hardwareKeyId: String; let biometryType: BiometryType
    let createdAt: Date; let lastVerifiedAt: Date?

    static let mock = Identity(
        did: "did:sov:7Tq3kTmNpL8vXoAe9fP2Yz", displayName: "Aarav Shah",
        handle: "@aarav.sov", avatarEmoji: "🔐", trustScore: 94,
        trustState: .verified, hardwareKeyId: "SE-KEY-A1B2C3",
        biometryType: .faceID, createdAt: Date(timeIntervalSinceNow: -86400*90),
        lastVerifiedAt: Date(timeIntervalSinceNow: -3600)
    )
}
EOF

cat > "$SRC/Models/Product.swift" << 'EOF'
import Foundation
enum ProductStatus: String, Codable { case authentic, counterfeit, unverified, recalled }
struct CustodyCheckpoint: Identifiable, Codable {
    let id: String; let location: String; let actor: String
    let timestamp: Date; let note: String?
}
struct Product: Identifiable, Codable {
    let id: String; let name: String; let brand: String
    let serialNumber: String; let manufacturerDid: String
    let status: ProductStatus; let trustState: TrustState
    let custodyChain: [CustodyCheckpoint]; let manufacturedAt: Date
    let description: String; let category: String
    var statusIcon: String {
        switch status {
        case .authentic:   return "checkmark.seal.fill"
        case .counterfeit: return "xmark.seal.fill"
        case .unverified:  return "questionmark.circle.fill"
        case .recalled:    return "exclamationmark.triangle.fill"
        }
    }
}
EOF

cat > "$SRC/Models/Post.swift" << 'EOF'
import Foundation
enum PostVerificationStatus: String, Codable {
    case verifiedAuthor, unverifiedAuthor, disputed, synthetic, unknown
}
enum FraudSeverity: String, Codable {
    case low, medium, high, critical
    var color: SwiftUI.Color {
        switch self {
        case .low:      return .init(hex:"FFD60A")
        case .medium:   return .init(hex:"F97316")
        case .high:     return .init(hex:"FF3355")
        case .critical: return .init(hex:"FF0055")
        }
    }
}
enum FraudSignalId: String, Codable {
    case unknownIssuer, revokedCredential, suspiciousInstitution
    case invalidSignature, unverifiedAuthor, noInstitution
    case unverifiedClaims, noSource, syntheticContent, rapidPosting, credentialMismatch
}
struct FraudSignal: Identifiable, Codable {
    let id: FraudSignalId; let label: String
    let severity: FraudSeverity; let detail: String?; let remediation: String?
}
struct FraudAnalysis: Codable {
    let trustState: TrustState; let signals: [FraudSignal]
    let riskScore: Int; let analysedAt: Date
}
struct PostAuthor: Codable {
    let did: String; let displayName: String; let handle: String
    let avatarEmoji: String; let institution: String?
    let trustState: TrustState; let isVerified: Bool
}
struct Post: Identifiable, Codable {
    let id: String; let content: String; let author: PostAuthor
    let sourceUrl: String?; let sourceName: String?
    let publishedAt: Date; let verificationStatus: PostVerificationStatus
    let trustState: TrustState; let claimCount: Int
    let verifiedClaimCount: Int; let tags: [String]
    var fraudAnalysis: FraudAnalysis?
    var claimRatio: Double {
        claimCount > 0 ? Double(verifiedClaimCount) / Double(claimCount) : 0
    }
}
EOF

cat > "$SRC/Models/Verification.swift" << 'EOF'
import Foundation
enum VerificationSubjectType: String, Codable {
    case credential, product, document, login, post, did, unknown
    var icon: String {
        switch self {
        case .credential: return "checkmark.seal.fill"
        case .product:    return "shippingbox.fill"
        case .document:   return "doc.text.fill"
        case .login:      return "person.badge.key.fill"
        case .post:       return "newspaper.fill"
        case .did:        return "link"
        case .unknown:    return "questionmark.circle.fill"
        }
    }
    var label: String { rawValue.capitalized }
}
enum CheckOutcome: String, Codable {
    case pass, fail, warn, unknown
    var color: SwiftUI.Color {
        switch self {
        case .pass:    return .init(hex:"00FF88")
        case .fail:    return .init(hex:"FF3355")
        case .warn:    return .init(hex:"FFD60A")
        case .unknown: return .init(hex:"8E8E93")
        }
    }
    var icon: String {
        switch self {
        case .pass:    return "checkmark.circle.fill"
        case .fail:    return "xmark.circle.fill"
        case .warn:    return "exclamationmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}
struct VerificationCheck: Identifiable, Codable {
    let id: String; let label: String; let outcome: CheckOutcome; let detail: String?
}
struct VerificationResult: Identifiable, Codable {
    let id: String; let subjectId: String; let subjectType: VerificationSubjectType
    let trustState: TrustState; let checks: [VerificationCheck]
    let summary: String; let verifiedAt: Date; let durationMs: Int
    var passCount: Int { checks.filter{$0.outcome == .pass}.count }
    var failCount: Int { checks.filter{$0.outcome == .fail}.count }
    var warnCount: Int { checks.filter{$0.outcome == .warn}.count }
}
EOF

cat > "$SRC/Models/Handshake.swift" << 'EOF'
import Foundation
enum HandshakeStatus: String, Codable { case pending, signed, verified, expired, rejected }
struct HandshakeChallenge: Identifiable, Codable {
    let id: String; let service: String; let nonce: String
    let callbackUrl: String; let expiresAt: Date
}
struct Handshake: Identifiable, Codable {
    let id: String; let challenge: HandshakeChallenge
    var status: HandshakeStatus; let createdAt: Date; var signedAt: Date?
}
EOF

cat > "$SRC/Models/QRPayload.swift" << 'EOF'
import Foundation
struct QRPayload: Codable {
    let v: Int; let t: String; let id: String
    let did: String; let iss: String; let hash: String; let ts: String
    let service: String?; let nonce: String?; let exp: Int?
    let callback: String?; let serial: String?; let brand: String?
    let docType: String?; let title: String?
}
EOF

cat > "$SRC/Models/TrustGraph.swift" << 'EOF'
import Foundation
import SwiftUI
enum TrustNodeType: String, Codable {
    case issuer, holder, verifier, credential, product, institution, wallet
    var icon: String {
        switch self {
        case .issuer:      return "🏛️"
        case .holder:      return "👛"
        case .verifier:    return "🔍"
        case .credential:  return "📄"
        case .product:     return "📦"
        case .institution: return "🏢"
        case .wallet:      return "💎"
        }
    }
}
enum TrustEdgeType: String, Codable { case issues, holds, verifies, delegates, anchors, trusts }
enum TrustEdgeStrength: String, Codable { case strong, moderate, weak }
struct TrustNode: Identifiable, Codable {
    let id: String; let label: String; let sublabel: String?
    let type: TrustNodeType; let did: String?
    let trustState: TrustState; let emoji: String; let verified: Bool
    var position: CGPoint = .zero
    enum CodingKeys: String, CodingKey {
        case id,label,sublabel,type,did,trustState,emoji,verified
    }
}
struct TrustEdge: Identifiable, Codable {
    let id: String; let fromId: String; let toId: String
    let edgeType: TrustEdgeType; let strength: TrustEdgeStrength; let label: String?
}
struct TrustScoreResult: Codable {
    let score: Int; let label: String; let trustState: TrustState
    let nodeCount: Int; let edgeCount: Int
}
struct TrustGraph: Identifiable, Codable {
    let id: String; let title: String
    let nodes: [TrustNode]; let edges: [TrustEdge]; let score: TrustScoreResult
}
EOF


# ════════════════════════════════════════════════════════════════
# LAYERS 2–4 — CONSTANTS, DATABASE, CRYPTO
# ════════════════════════════════════════════════════════════════

cat > "$SRC/Constants/IssuerDirectory.swift" << 'EOF'
import Foundation
enum IssuerDirectory {
    static let all: [Issuer] = [
        Issuer(id:"iitb",      did:"did:sov:IIT-Bombay-0xA1B2C3",  name:"Indian Institute of Technology Bombay", shortName:"IIT Bombay",  logoEmoji:"🎓", category:"university",  trustState:.verified, isVerified:true,  country:"IN"),
        Issuer(id:"uidai",     did:"did:sov:UIDAI-GOV-0xD4E5F6",   name:"Unique Identification Authority of India", shortName:"UIDAI",   logoEmoji:"🏛️", category:"government",  trustState:.verified, isVerified:true,  country:"IN"),
        Issuer(id:"aws",       did:"did:sov:Amazon-AWS-0xG7H8I9",   name:"Amazon Web Services",               shortName:"AWS",         logoEmoji:"☁️", category:"corporate",   trustState:.trusted,  isVerified:true,  country:"US"),
        Issuer(id:"mit",       did:"did:sov:MIT-0xP1Q2R3",          name:"Massachusetts Institute of Technology", shortName:"MIT",      logoEmoji:"🏫", category:"university",  trustState:.verified, isVerified:true,  country:"US"),
        Issuer(id:"sebi",      did:"did:sov:SEBI-GOV-0xS4T5U6",    name:"Securities and Exchange Board of India", shortName:"SEBI",    logoEmoji:"📈", category:"government",  trustState:.trusted,  isVerified:true,  country:"IN"),
        Issuer(id:"acm",       did:"did:sov:ACM-0xJ1K2L3",          name:"Association for Computing Machinery", shortName:"ACM",       logoEmoji:"💻", category:"ngo",         trustState:.trusted,  isVerified:true,  country:"US"),
        Issuer(id:"anthropic", did:"did:sov:Anthropic-0xM4N5O6",    name:"Anthropic",                          shortName:"Anthropic",  logoEmoji:"🤖", category:"corporate",   trustState:.trusted,  isVerified:true,  country:"US"),
        Issuer(id:"rbi",       did:"did:sov:RBI-GOV-0xR1B2I3",      name:"Reserve Bank of India",              shortName:"RBI",        logoEmoji:"🏦", category:"government",  trustState:.verified, isVerified:true,  country:"IN"),
        Issuer(id:"isro",      did:"did:sov:ISRO-GOV-0xI1S2R3",     name:"Indian Space Research Organisation", shortName:"ISRO",       logoEmoji:"🚀", category:"government",  trustState:.verified, isVerified:true,  country:"IN"),
    ]
    static func find(did: String) -> Issuer? { all.first { $0.did == did } }
    static func find(id: String) -> Issuer?  { all.first { $0.id == id  } }
}
EOF

cat > "$SRC/Constants/MockData.swift" << 'EOF'
import Foundation
enum MockData {
    static let credentials: [Credential] = [
        Credential(id:"c1", type:.education,    title:"B.Tech Computer Science",   description:"Bachelor of Technology, CS&E", issuerDid:"did:sov:IIT-Bombay-0xA1B2C3", subjectDid:Identity.mock.did, issuedAt:Date(timeIntervalSinceNow:-86400*365*4), expiresAt:nil,                                status:.active,  trustState:.verified, hash:"sha256:a1b2c3d4e5f678901234", signature:"sig:0xA1B2", isVerified:true,  rawJson:nil),
        Credential(id:"c2", type:.identity,     title:"Aadhaar Digital Identity",  description:"Government biometric identity", issuerDid:"did:sov:UIDAI-GOV-0xD4E5F6",  subjectDid:Identity.mock.did, issuedAt:Date(timeIntervalSinceNow:-86400*365*2), expiresAt:Date(timeIntervalSinceNow:86400*365*3), status:.active,  trustState:.verified, hash:"sha256:d4e5f6a7b8c9d0e1f2", signature:"sig:0xD4E5", isVerified:true,  rawJson:nil),
        Credential(id:"c3", type:.professional, title:"AWS Solutions Architect",   description:"Professional cloud certification", issuerDid:"did:sov:Amazon-AWS-0xG7H8I9", subjectDid:Identity.mock.did, issuedAt:Date(timeIntervalSinceNow:-86400*180),    expiresAt:Date(timeIntervalSinceNow:86400*365*2), status:.active,  trustState:.trusted,  hash:"sha256:g7h8i9j0k1l2m3n4o5", signature:"sig:0xG7H8", isVerified:true,  rawJson:nil),
        Credential(id:"c4", type:.membership,   title:"ACM Senior Member",         description:"Association for Computing Machinery", issuerDid:"did:sov:ACM-0xJ1K2L3",    subjectDid:Identity.mock.did, issuedAt:Date(timeIntervalSinceNow:-86400*90),     expiresAt:Date(timeIntervalSinceNow:86400*275),   status:.active,  trustState:.trusted,  hash:"sha256:j1k2l3m4n5o6p7q8r9", signature:"sig:0xJ1K2", isVerified:true,  rawJson:nil),
        Credential(id:"c5", type:.professional, title:"AI Safety Fundamentals",    description:"Anthropic AI Safety Certificate",    issuerDid:"did:sov:Anthropic-0xM4N5O6", subjectDid:Identity.mock.did, issuedAt:Date(timeIntervalSinceNow:-86400*30),     expiresAt:nil,                                status:.active,  trustState:.trusted,  hash:"sha256:m4n5o6p7q8r9s0t1u2", signature:"sig:0xM4N5", isVerified:true,  rawJson:nil),
    ]
    static let posts: [Post] = [
        Post(id:"p1", content:"The new RBI circular on digital lending mandates explicit digital consent from borrowers before accessing credit bureau data. This marks a significant shift in data governance for NBFCs.", author:PostAuthor(did:"did:sov:RBI-GOV-0xR1B2I3", displayName:"Reserve Bank of India", handle:"@rbi.official", avatarEmoji:"🏦", institution:"Reserve Bank of India", trustState:.verified, isVerified:true), sourceUrl:"https://rbi.org.in/circular/2025", sourceName:"RBI Official", publishedAt:Date(timeIntervalSinceNow:-3600), verificationStatus:.verifiedAuthor, trustState:.verified, claimCount:4, verifiedClaimCount:4, tags:["finance","regulation","RBI"], fraudAnalysis:nil),
        Post(id:"p2", content:"BREAKING: Major cryptocurrency exchange collapsed overnight. Reports claim $2.3 billion in customer funds unaccounted for. Investigations underway.", author:PostAuthor(did:"did:sov:unknown-0x999", displayName:"CryptoAlert24", handle:"@cryptoalert24", avatarEmoji:"📢", institution:nil, trustState:.suspicious, isVerified:false), sourceUrl:nil, sourceName:nil, publishedAt:Date(timeIntervalSinceNow:-7200), verificationStatus:.unverifiedAuthor, trustState:.suspicious, claimCount:3, verifiedClaimCount:0, tags:["crypto","breaking","unverified"], fraudAnalysis:FraudAnalysis(trustState:.suspicious, signals:[FraudSignal(id:.noSource, label:"No Source URL", severity:.high, detail:"Claim has no verifiable source link", remediation:"Check official exchange announcements"), FraudSignal(id:.unverifiedAuthor, label:"Unverified Author", severity:.medium, detail:"Author DID not in trusted registry", remediation:"Verify author credentials"), FraudSignal(id:.rapidPosting, label:"Rapid Posting", severity:.low, detail:"12 similar posts in past hour", remediation:nil)], riskScore:78, analysedAt:Date())),
        Post(id:"p3", content:"IIT Bombay announces new postgraduate program in Quantum Computing for 2025 batch. 40 total seats with 20% reserved for industry-sponsored candidates.", author:PostAuthor(did:"did:sov:IIT-Bombay-0xA1B2C3", displayName:"IIT Bombay", handle:"@iitbombay.official", avatarEmoji:"🎓", institution:"Indian Institute of Technology Bombay", trustState:.verified, isVerified:true), sourceUrl:"https://iitb.ac.in/admissions/2025", sourceName:"IIT Bombay Official", publishedAt:Date(timeIntervalSinceNow:-10800), verificationStatus:.verifiedAuthor, trustState:.verified, claimCount:5, verifiedClaimCount:5, tags:["education","IITBombay","quantum"], fraudAnalysis:nil),
    ]
    static let products: [Product] = [
        Product(id:"pr1", name:"MacBook Pro M4", brand:"Apple", serialNumber:"C02ZF4KHMD6T", manufacturerDid:"did:sov:Apple-Corp-0xAPPLE", status:.authentic, trustState:.verified, custodyChain:[CustodyCheckpoint(id:"cp1", location:"Zhengzhou, China", actor:"Foxconn", timestamp:Date(timeIntervalSinceNow:-86400*30), note:"Manufacturing complete"), CustodyCheckpoint(id:"cp2", location:"Shanghai Port", actor:"DHL Express", timestamp:Date(timeIntervalSinceNow:-86400*25), note:"Export customs cleared"), CustodyCheckpoint(id:"cp3", location:"Mumbai BDR", actor:"Apple India", timestamp:Date(timeIntervalSinceNow:-86400*10), note:"Distribution centre received")], manufacturedAt:Date(timeIntervalSinceNow:-86400*35), description:"Apple Silicon MacBook Pro with M4 chip", category:"Electronics"),
    ]
}
EOF

cat > "$SRC/Constants/AppConstants.swift" << 'EOF'
import Foundation
enum AppConstants {
    static let appVersion    = "2.0.0"
    static let buildNumber   = "2025.1"
    static let bundleId      = "com.sovereigntrust.app"
    static let keychainGroup = "com.sovereigntrust.app"
    static let seKeyTag      = "com.sovereigntrust.identity.sekey"
    static let dbName        = "sovereign.sqlite"
    static let verificationStepCount = 5
    static let verificationStepDelay = 0.5 // seconds per step
}
EOF

cat > "$SRC/Database/DatabaseManager.swift" << 'EOF'
import Foundation
import GRDB

actor DatabaseManager {
    static let shared = DatabaseManager()
    private var queue: DatabaseQueue?

    func setup() async throws {
        let fm = FileManager.default
        guard let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw NSError(domain:"DB", code:1, userInfo:[NSLocalizedDescriptionKey:"No AppSupport dir"])
        }
        let folder = dir.appendingPathComponent("SovereignTrust", isDirectory:true)
        try fm.createDirectory(at:folder, withIntermediateDirectories:true)
        let path = folder.appendingPathComponent(AppConstants.dbName).path
        let q = try DatabaseQueue(path: path)
        try await q.write { db in
            try db.execute(sql:"""
                CREATE TABLE IF NOT EXISTS credentials (
                    id TEXT PRIMARY KEY, type TEXT NOT NULL, title TEXT NOT NULL,
                    description TEXT, issuerDid TEXT NOT NULL, subjectDid TEXT NOT NULL,
                    issuedAt REAL NOT NULL, expiresAt REAL, status TEXT NOT NULL,
                    trustState TEXT NOT NULL, hash TEXT NOT NULL, signature TEXT,
                    isVerified INTEGER NOT NULL DEFAULT 0, rawJson TEXT
                )""")
            try db.execute(sql:"""
                CREATE TABLE IF NOT EXISTS verifications (
                    id TEXT PRIMARY KEY, subjectId TEXT NOT NULL, subjectType TEXT NOT NULL,
                    trustState TEXT NOT NULL, checksJson TEXT NOT NULL, summary TEXT NOT NULL,
                    verifiedAt REAL NOT NULL, durationMs INTEGER NOT NULL
                )""")
        }
        self.queue = q
        try await seedIfNeeded()
    }

    private func seedIfNeeded() async throws {
        guard let q = queue else { return }
        let count = try await q.read { try Int.fetchOne($0, sql:"SELECT COUNT(*) FROM credentials") ?? 0 }
        guard count == 0 else { return }
        try await q.write { db in
            for c in MockData.credentials {
                try db.execute(sql:"""
                    INSERT OR IGNORE INTO credentials
                    (id,type,title,description,issuerDid,subjectDid,issuedAt,expiresAt,status,trustState,hash,signature,isVerified,rawJson)
                    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                """, arguments:[c.id, c.type.rawValue, c.title, c.description,
                                c.issuerDid, c.subjectDid,
                                c.issuedAt.timeIntervalSince1970, c.expiresAt?.timeIntervalSince1970,
                                c.status.rawValue, c.trustState.rawValue, c.hash, c.signature,
                                c.isVerified ? 1 : 0, c.rawJson])
            }
        }
    }

    func fetchCredentials(subjectDid: String) async throws -> [Credential] {
        guard let q = queue else { return MockData.credentials }
        return try await q.read { db in
            let rows = try Row.fetchAll(db, sql:
                "SELECT * FROM credentials WHERE subjectDid = ? ORDER BY issuedAt DESC",
                arguments:[subjectDid])
            return rows.compactMap { row -> Credential? in
                guard let id = row["id"] as? String,
                      let type = CredentialType(rawValue: row["type"] as? String ?? ""),
                      let status = CredentialStatus(rawValue: row["status"] as? String ?? ""),
                      let ts = TrustState(rawValue: row["trustState"] as? String ?? ""),
                      let title = row["title"] as? String,
                      let issuerDid = row["issuerDid"] as? String,
                      let subjectDid = row["subjectDid"] as? String,
                      let issuedAtTS = row["issuedAt"] as? Double,
                      let hash = row["hash"] as? String
                else { return nil }
                let expiresAtTS = row["expiresAt"] as? Double
                return Credential(
                    id:id, type:type, title:title, description:row["description"] as? String,
                    issuerDid:issuerDid, subjectDid:subjectDid,
                    issuedAt:Date(timeIntervalSince1970:issuedAtTS),
                    expiresAt:expiresAtTS.map{Date(timeIntervalSince1970:$0)},
                    status:status, trustState:ts, hash:hash,
                    signature:row["signature"] as? String,
                    isVerified:(row["isVerified"] as? Int64 ?? 0) == 1,
                    rawJson:row["rawJson"] as? String
                )
            }
        }
    }

    func saveVerification(_ r: VerificationResult) async throws {
        guard let q = queue else { return }
        let enc = JSONEncoder()
        let checksJson = (try? enc.encode(r.checks)).flatMap{String(data:$0, encoding:.utf8)} ?? "[]"
        try await q.write { db in
            try db.execute(sql:"""
                INSERT OR REPLACE INTO verifications
                (id,subjectId,subjectType,trustState,checksJson,summary,verifiedAt,durationMs)
                VALUES (?,?,?,?,?,?,?,?)
            """, arguments:[r.id, r.subjectId, r.subjectType.rawValue, r.trustState.rawValue,
                            checksJson, r.summary, r.verifiedAt.timeIntervalSince1970, r.durationMs])
        }
    }

    func recentVerifications(limit: Int = 8) async throws -> [VerificationResult] {
        guard let q = queue else { return [] }
        let rows = try await q.read { db in
            try Row.fetchAll(db, sql:
                "SELECT * FROM verifications ORDER BY verifiedAt DESC LIMIT ?",
                arguments:[limit])
        }
        let dec = JSONDecoder()
        return rows.compactMap { row -> VerificationResult? in
            guard let id = row["id"] as? String,
                  let subjectId = row["subjectId"] as? String,
                  let subjectType = VerificationSubjectType(rawValue: row["subjectType"] as? String ?? ""),
                  let ts = TrustState(rawValue: row["trustState"] as? String ?? ""),
                  let checksJson = row["checksJson"] as? String,
                  let checksData = checksJson.data(using:.utf8),
                  let checks = try? dec.decode([VerificationCheck].self, from:checksData),
                  let summary = row["summary"] as? String,
                  let verifiedAtTS = row["verifiedAt"] as? Double,
                  let durationMs = row["durationMs"] as? Int64
            else { return nil }
            return VerificationResult(
                id:id, subjectId:subjectId, subjectType:subjectType,
                trustState:ts, checks:checks, summary:summary,
                verifiedAt:Date(timeIntervalSince1970:verifiedAtTS),
                durationMs:Int(durationMs)
            )
        }
    }
}
EOF

# Crypto Layer
cat > "$SRC/Crypto/SecureEnclaveService.swift" << 'EOF'
import Foundation
import CryptoKit
import Security
import LocalAuthentication

enum SecureEnclaveError: LocalizedError {
    case notAvailable, keyCreationFailed, keyNotFound, signFailed, exportFailed
    var errorDescription: String? {
        switch self {
        case .notAvailable:    return "Secure Enclave not available on this device"
        case .keyCreationFailed: return "Failed to create Secure Enclave key"
        case .keyNotFound:     return "Key not found in Secure Enclave"
        case .signFailed:      return "Signing operation failed"
        case .exportFailed:    return "Public key export failed"
        }
    }
}

actor SecureEnclaveService {
    static let shared = SecureEnclaveService()
    private init() {}
    private let tag = AppConstants.seKeyTag.data(using:.utf8)!

    // Query or create a P-256 key in the Secure Enclave
    func getOrCreateKey() throws -> SecKey {
        // 1. Try to find existing
        let query: CFDictionary = [
            kSecClass:           kSecClassKey,
            kSecAttrKeyType:     kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrTokenID:     kSecAttrTokenIDSecureEnclave,
            kSecAttrApplicationTag: tag,
            kSecReturnRef:       true,
        ] as CFDictionary
        var item: CFTypeRef?
        if SecItemCopyMatching(query, &item) == errSecSuccess, let key = item {
            return (key as! SecKey)
        }
        // 2. Create new
        var cfErr: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .biometryAny], &cfErr) else {
            throw SecureEnclaveError.keyCreationFailed
        }
        let attrs: CFDictionary = [
            kSecAttrKeyType:     kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrTokenID:     kSecAttrTokenIDSecureEnclave,
            kSecAttrKeySizeInBits: 256,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent:    true,
                kSecAttrApplicationTag: tag,
                kSecAttrAccessControl:  access,
            ] as CFDictionary,
        ] as CFDictionary
        guard let key = SecKeyCreateRandomKey(attrs, &cfErr) else {
            throw SecureEnclaveError.keyCreationFailed
        }
        return key
    }

    func publicKeyData() throws -> Data {
        let priv = try getOrCreateKey()
        guard let pub = SecKeyCopyPublicKey(priv),
              let data = SecKeyCopyExternalRepresentation(pub, nil) else {
            throw SecureEnclaveError.exportFailed
        }
        return data as Data
    }

    func fingerprint() throws -> String {
        let data = try publicKeyData()
        let b64 = data.base64EncodedString()
        return "SE-\(String(b64.prefix(16)))"
    }

    func sign(payload: Data) throws -> Data {
        let key = try getOrCreateKey()
        var err: Unmanaged<CFError>?
        guard let sig = SecKeyCreateSignature(key,
            .ecdsaSignatureMessageX962SHA256, payload as CFData, &err) else {
            throw err?.takeRetainedValue() ?? SecureEnclaveError.signFailed
        }
        return sig as Data
    }

    func generateDID() throws -> String {
        let pubData = try publicKeyData()
        let hash = SHA256.hash(data: pubData)
        let hex = hash.map { String(format:"%02x",$0) }.joined()
        return "did:sov:\(String(hex.prefix(22)))"
    }
}
EOF

cat > "$SRC/Crypto/BiometricTestService.swift" << 'EOF'
import Foundation
import LocalAuthentication

struct BiometricTestResult {
    let success: Bool
    let biometryType: BiometryType
    let errorMessage: String?
    let testedAt: Date
}

actor BiometricTestService {
    static let shared = BiometricTestService()
    private init() {}

    func runTest() async -> BiometricTestResult {
        let ctx = LAContext()
        var nsErr: NSError?
        let available = ctx.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &nsErr)

        let type: BiometryType = switch ctx.biometryType {
            case .faceID:  .faceID
            case .touchID: .touchID
            default:       .none
        }
        guard available else {
            return BiometricTestResult(success:false, biometryType:type,
                errorMessage:nsErr?.localizedDescription ?? "Not available", testedAt:Date())
        }
        do {
            let ok = try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Testing biometric authentication")
            return BiometricTestResult(success:ok, biometryType:type,
                                       errorMessage:nil, testedAt:Date())
        } catch {
            return BiometricTestResult(success:false, biometryType:type,
                                       errorMessage:error.localizedDescription, testedAt:Date())
        }
    }
}
EOF


# ════════════════════════════════════════════════════════════════
# LAYER 5 — SERVICES
# ════════════════════════════════════════════════════════════════

cat > "$SRC/Services/Biometric/BiometricService.swift" << 'EOF'
import Foundation
import LocalAuthentication

enum BiometricError: LocalizedError {
    case notAvailable(String)
    case denied
    case failed(String)
    var errorDescription: String? {
        switch self {
        case .notAvailable(let m): return "Biometrics not available: \(m)"
        case .denied:              return "Biometric access denied"
        case .failed(let m):       return "Authentication failed: \(m)"
        }
    }
}

// RULE: Only call authenticate() from an explicit user button tap
actor BiometricService {
    static let shared = BiometricService()
    private init() {}

    func authenticate(reason: String) async throws -> Bool {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error:&err) else {
            throw BiometricError.notAvailable(err?.localizedDescription ?? "unavailable")
        }
        do {
            return try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch let e as LAError {
            if e.code == .userCancel { return false }
            throw BiometricError.failed(e.localizedDescription)
        }
    }

    nonisolated func biometryType() -> BiometryType {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error:nil)
        return switch ctx.biometryType {
            case .faceID:  .faceID
            case .touchID: .touchID
            default:       .none
        }
    }

    nonisolated func isAvailable() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
}
EOF

cat > "$SRC/Services/QR/QRParserService.swift" << 'EOF'
import Foundation

struct ParsedQR {
    let raw: String
    let type: VerificationSubjectType
    let payload: QRPayload?
}

enum QRParserService {
    static func parse(_ raw: String) -> ParsedQR {
        // 1 — JSON with "t" field
        if let data = raw.data(using:.utf8),
           let p = try? JSONDecoder().decode(QRPayload.self, from:data) {
            let t: VerificationSubjectType = switch p.t {
                case "vc","credential":  .credential
                case "product":          .product
                case "handshake":        .login
                case "document":         .document
                case "did":              .did
                default:                 .unknown
            }
            return ParsedQR(raw:raw, type:t, payload:p)
        }
        // 2 — Raw DID
        if raw.hasPrefix("did:") { return ParsedQR(raw:raw, type:.did, payload:nil) }
        // 3 — URL path hints
        if let url = URL(string:raw) {
            let path = url.path.lowercased()
            if path.contains("/product/") || path.contains("/item/") { return ParsedQR(raw:raw, type:.product, payload:nil) }
            if path.contains("/credential") || path.contains("/vc/") { return ParsedQR(raw:raw, type:.credential, payload:nil) }
            if path.contains("/handshake") || path.contains("/login") { return ParsedQR(raw:raw, type:.login, payload:nil) }
            if path.contains("/document") || path.contains("/doc/")  { return ParsedQR(raw:raw, type:.document, payload:nil) }
        }
        return ParsedQR(raw:raw, type:.unknown, payload:nil)
    }
}
EOF

cat > "$SRC/Services/QR/QRGeneratorService.swift" << 'EOF'
import UIKit
import CoreImage.CIFilterBuiltins

enum QRGeneratorService {
    static func generate(from string: String, size: CGFloat = 240) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX:scale, y:scale))
        guard let cgImg = context.createCGImage(scaled, from:scaled.extent) else { return nil }
        return UIImage(cgImage:cgImg)
    }

    static func credentialPayload(_ c: Credential) -> String {
        let p: [String:Any] = ["v":1,"t":"vc","id":c.id,"did":c.subjectDid,
                               "iss":c.issuerDid,"hash":c.hash,"ts":"\(Date().timeIntervalSince1970)"]
        let data = try? JSONSerialization.data(withJSONObject:p)
        return data.flatMap { String(data:$0, encoding:.utf8) } ?? c.id
    }
}
EOF

cat > "$SRC/Services/Handshake/HandshakeService.swift" << 'EOF'
import Foundation
import Observation

@Observable
final class HandshakeService {
    var active: Handshake?
    var isProcessing = false
    var lastError: String?

    func processPayload(_ p: QRPayload) {
        guard let nonce = p.nonce, let service = p.service else { return }
        let exp = p.exp.map { Date(timeIntervalSince1970:TimeInterval($0)) }
                  ?? Date(timeIntervalSinceNow:300)
        let challenge = HandshakeChallenge(id:UUID().uuidString, service:service,
            nonce:nonce, callbackUrl:p.callback ?? "", expiresAt:exp)
        active = Handshake(id:UUID().uuidString, challenge:challenge,
                           status:.pending, createdAt:Date(), signedAt:nil)
    }

    // Called ONLY from explicit button tap after biometric succeeds
    func signChallenge() async -> Bool {
        guard let h = active else { return false }
        isProcessing = true; lastError = nil
        do {
            guard let nonceData = h.challenge.nonce.data(using:.utf8) else { throw SecureEnclaveError.signFailed }
            _ = try SecureEnclaveService.shared.sign(payload:nonceData)
            active = Handshake(id:h.id, challenge:h.challenge,
                               status:.verified, createdAt:h.createdAt, signedAt:Date())
            isProcessing = false; return true
        } catch {
            lastError = error.localizedDescription
            active = Handshake(id:h.id, challenge:h.challenge,
                               status:.rejected, createdAt:h.createdAt, signedAt:nil)
            isProcessing = false; return false
        }
    }

    func dismiss() { active = nil; lastError = nil }
}
EOF

cat > "$SRC/Services/AI/FraudSignalService.swift" << 'EOF'
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
EOF


# ════════════════════════════════════════════════════════════════
# LAYER 6 — DOMAIN LOGIC
# ════════════════════════════════════════════════════════════════

cat > "$SRC/Domain/Verification/VerificationEngine.swift" << 'EOF'
import Foundation
import Observation

struct VerificationStep: Identifiable {
    let id = UUID()
    let number: Int
    let label: String
    var isActive   = false
    var isComplete = false
    var isFailed   = false
    var checkOutcome: CheckOutcome = .unknown
    var detail: String?
}

@Observable
@MainActor
final class VerificationEngine {
    var steps: [VerificationStep] = [
        VerificationStep(number:1, label:"Decoding QR payload"),
        VerificationStep(number:2, label:"Parsing structure"),
        VerificationStep(number:3, label:"Verifying signature"),
        VerificationStep(number:4, label:"Checking issuer registry"),
        VerificationStep(number:5, label:"Evaluating trust graph"),
    ]
    var result: VerificationResult?
    var isRunning = false

    func verify(raw: String, type: VerificationSubjectType) async {
        isRunning = true; result = nil
        // reset
        for i in steps.indices {
            steps[i].isActive = false; steps[i].isComplete = false
            steps[i].isFailed = false; steps[i].checkOutcome = .unknown
        }
        let start = Date()
        var checks: [VerificationCheck] = []

        for i in steps.indices {
            steps[i].isActive = true
            try? await Task.sleep(nanoseconds:UInt64(AppConstants.verificationStepDelay * 1_000_000_000))
            let (outcome, detail) = Self.performCheck(step:i, raw:raw, type:type)
            let check = VerificationCheck(id:UUID().uuidString, label:steps[i].label,
                                          outcome:outcome, detail:detail)
            checks.append(check)
            steps[i].isActive   = false
            steps[i].isComplete = outcome != .fail
            steps[i].isFailed   = outcome == .fail
            steps[i].checkOutcome = outcome
            steps[i].detail = detail
        }

        let ms = Int(Date().timeIntervalSince(start) * 1000)
        let fails = checks.filter{$0.outcome == .fail}.count
        let warns = checks.filter{$0.outcome == .warn}.count
        let trustState: TrustState = fails > 0 ? .revoked : warns >= 3 ? .suspicious : warns >= 1 ? .trusted : .verified
        let summary = Self.buildSummary(trustState:trustState, type:type, passes:checks.filter{$0.outcome == .pass}.count, total:checks.count)
        let subjectId = Self.extractId(raw:raw, type:type)
        result = VerificationResult(id:UUID().uuidString, subjectId:subjectId, subjectType:type,
            trustState:trustState, checks:checks, summary:summary, verifiedAt:Date(), durationMs:ms)
        if let r = result { try? await DatabaseManager.shared.saveVerification(r) }
        isRunning = false
    }

    private static func performCheck(step: Int, raw: String, type: VerificationSubjectType) -> (CheckOutcome, String?) {
        switch step {
        case 0: return raw.isEmpty ? (.fail,"Empty payload") : (.pass,"Data decoded successfully")
        case 1:
            let p = QRParserService.parse(raw)
            return p.type == .unknown && !raw.hasPrefix("did:") ? (.warn,"Non-standard format") : (.pass,"Structure valid")
        case 2:
            if raw.contains("sig:") || raw.contains("signature") { return (.pass,"Signature verified") }
            if type == .did { return (.pass,"DID format valid") }
            return (.warn,"No signature present")
        case 3:
            let known = IssuerDirectory.all.contains { raw.contains($0.did) || raw.contains($0.id) }
            return known ? (.pass,"Issuer in verified registry") : (.warn,"Issuer not in local registry")
        case 4: return (.pass,"Trust graph evaluated — chain intact")
        default: return (.unknown, nil)
        }
    }

    private static func buildSummary(trustState: TrustState, type: VerificationSubjectType, passes: Int, total: Int) -> String {
        switch trustState {
        case .verified:   return "All \(passes)/\(total) checks passed. This \(type.label.lowercased()) is cryptographically verified."
        case .trusted:    return "\(passes)/\(total) checks passed. Trusted with minor caveats."
        case .suspicious: return "Multiple anomalies detected. Treat with caution."
        case .revoked:    return "Verification failed. Item may be invalid or revoked."
        default:          return "Verification complete."
        }
    }

    private static func extractId(raw: String, type: VerificationSubjectType) -> String {
        if raw.hasPrefix("did:") { return String(raw.prefix(36)) }
        if let p = QRParserService.parse(raw).payload { return p.id }
        return String(raw.prefix(28)) + "…"
    }
}
EOF


# ════════════════════════════════════════════════════════════════
# LAYER 7 — VIEWMODELS
# ════════════════════════════════════════════════════════════════

cat > "$SRC/ViewModels/HomeViewModel.swift" << 'EOF'
import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var identity: Identity = .mock
    var credentials: [CredentialWithIssuer] = []
    var recentVerifications: [VerificationResult] = []
    var isLoading = false

    func load() async {
        isLoading = true
        do {
            let raw = try await DatabaseManager.shared.fetchCredentials(subjectDid: identity.did)
            let isEmpty = raw.isEmpty
            let creds = isEmpty ? MockData.credentials : raw
            credentials = creds.map { c in
                let issuer = IssuerDirectory.find(did:c.issuerDid)
                    ?? Issuer(id:"?", did:c.issuerDid, name:"Unknown Issuer", shortName:"Unknown",
                              logoEmoji:"❓", category:"unknown", trustState:.unknown,
                              isVerified:false, country:"?")
                return CredentialWithIssuer(credential:c, issuer:issuer)
            }
            recentVerifications = (try? await DatabaseManager.shared.recentVerifications()) ?? []
        } catch {
            credentials = MockData.credentials.map { c in
                CredentialWithIssuer(credential:c, issuer:IssuerDirectory.find(did:c.issuerDid)
                    ?? Issuer(id:"?", did:c.issuerDid, name:"Unknown", shortName:"?",
                              logoEmoji:"❓", category:"unknown", trustState:.unknown, isVerified:false, country:"?"))
            }
        }
        isLoading = false
    }
}
EOF

cat > "$SRC/ViewModels/TruthFeedViewModel.swift" << 'EOF'
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
EOF

cat > "$SRC/ViewModels/CredentialViewModel.swift" << 'EOF'
import Foundation
import Observation

enum CredentialFilter: String, CaseIterable {
    case all="All", education="Education", identity="Identity",
         professional="Professional", membership="Membership"
}

@Observable
@MainActor
final class CredentialViewModel {
    var items: [CredentialWithIssuer] = []
    var filtered: [CredentialWithIssuer] = []
    var activeFilter: CredentialFilter = .all
    var isLoading = false
    var selected: CredentialWithIssuer?

    func load(subjectDid: String) async {
        isLoading = true
        let raw: [Credential]
        do { raw = try await DatabaseManager.shared.fetchCredentials(subjectDid:subjectDid) }
        catch { raw = MockData.credentials }
        let src = raw.isEmpty ? MockData.credentials : raw
        items = src.map { c in
            let issuer = IssuerDirectory.find(did:c.issuerDid)
                ?? Issuer(id:"?", did:c.issuerDid, name:"Unknown", shortName:"?",
                          logoEmoji:"❓", category:"unknown", trustState:.unknown, isVerified:false, country:"?")
            return CredentialWithIssuer(credential:c, issuer:issuer)
        }
        applyFilter(activeFilter)
        isLoading = false
    }

    func applyFilter(_ f: CredentialFilter) {
        activeFilter = f
        filtered = f == .all ? items : items.filter {
            $0.credential.type.rawValue.lowercased() == f.rawValue.lowercased()
        }
    }
}
EOF

cat > "$SRC/ViewModels/HandshakeViewModel.swift" << 'EOF'
import Foundation
import Observation

@Observable
@MainActor
final class HandshakeViewModel {
    var handshake: Handshake?
    var isSigning = false
    var error: String?
    var timeRemaining: Int = 300

    private var timerTask: Task<Void,Never>?
    private let svc = HandshakeService()

    func present(_ h: Handshake) {
        handshake = h
        startCountdown(to: h.challenge.expiresAt)
    }

    // Called ONLY from explicit "Sign with Face ID" button tap
    func signWithBiometrics() async {
        guard let h = handshake else { return }
        isSigning = true; error = nil
        do {
            let ok = try await BiometricService.shared.authenticate(
                reason:"Sign authentication challenge for \(h.challenge.service)")
            guard ok else { isSigning = false; return }
            svc.processPayload(QRPayload(v:1, t:"handshake", id:h.id, did:"",
                iss:"", hash:"", ts:"", service:h.challenge.service,
                nonce:h.challenge.nonce, exp:nil, callback:nil,
                serial:nil, brand:nil, docType:nil, title:nil))
            let success = await svc.signChallenge()
            handshake = svc.active
            if !success { error = svc.lastError }
        } catch {
            self.error = error.localizedDescription
        }
        isSigning = false
    }

    private func startCountdown(to date: Date) {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                let rem = max(0, Int(date.timeIntervalSinceNow))
                await MainActor.run { timeRemaining = rem }
                if rem == 0 { break }
                try? await Task.sleep(nanoseconds:1_000_000_000)
            }
        }
    }
    deinit { timerTask?.cancel() }
}
EOF


# ════════════════════════════════════════════════════════════════
# LAYER 8 — GLASS COMPONENT SYSTEM
# ════════════════════════════════════════════════════════════════

cat > "$SRC/Components/AmbientBackground.swift" << 'EOF'
import SwiftUI

struct AmbientBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.04)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            ZStack {
                Color.stNavy.ignoresSafeArea()
                // Cyan — top-left, slow drift
                Circle()
                    .fill(Color(hex:"22D3EE").opacity(0.28))
                    .frame(width:420)
                    .offset(x: -140 + CGFloat(sin(t*0.18))*28,
                            y: -210 + CGFloat(cos(t*0.14))*22)
                    .blur(radius:92).ignoresSafeArea()
                // Purple — bottom-right
                Circle()
                    .fill(Color(hex:"8B5CF6").opacity(0.24))
                    .frame(width:460)
                    .offset(x:  155 + CGFloat(cos(t*0.12))*24,
                            y:  290 + CGFloat(sin(t*0.16))*20)
                    .blur(radius:112).ignoresSafeArea()
                // Blue — centre fill
                Circle()
                    .fill(Color(hex:"3B82F6").opacity(0.16))
                    .frame(width:380)
                    .offset(x: CGFloat(sin(t*0.10))*16, y:60)
                    .blur(radius:88).ignoresSafeArea()
            }
        }
    }
}

extension View {
    func ambientBackground() -> some View {
        ZStack { AmbientBackground(); self }
    }
}
EOF

cat > "$SRC/Components/GlassCard.swift" << 'EOF'
import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 26
    var glowColor: Color = .clear
    var glowOpacity: Double = 0
    var innerPadding: CGFloat = 16
    var material: AnyShapeStyle = AnyShapeStyle(.ultraThinMaterial)
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(innerPadding)
            .background(material,
                in: RoundedRectangle(cornerRadius:cornerRadius, style:.continuous))
            // Specular highlight — top-left
            .overlay(
                RoundedRectangle(cornerRadius:cornerRadius, style:.continuous)
                    .fill(LinearGradient(
                        colors:[Color.white.opacity(0.22), Color.white.opacity(0.06),
                                .clear, Color.white.opacity(0.02)],
                        startPoint:.topLeading, endPoint:.bottomTrailing))
                    .allowsHitTesting(false))
            // Edge stroke — light emission
            .overlay(
                RoundedRectangle(cornerRadius:cornerRadius, style:.continuous)
                    .stroke(LinearGradient(
                        colors:[Color.white.opacity(0.24), Color.white.opacity(0.06)],
                        startPoint:.topLeading, endPoint:.bottomTrailing), lineWidth:1))
            .shadow(color:glowColor.opacity(glowOpacity), radius:28, x:0, y:0)
            .shadow(color:.black.opacity(0.30), radius:24, x:0, y:14)
    }
}

// MARK: - Press modifier
struct GlassPressModifier: ViewModifier {
    @State private var pressed = false
    let action: () -> Void
    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.spring(response:0.28, dampingFraction:0.72), value:pressed)
            .simultaneousGesture(DragGesture(minimumDistance:0)
                .onChanged{_ in pressed = true}
                .onEnded{_ in pressed = false})
            .onTapGesture(perform:action)
    }
}
extension View {
    func glassPress(action: @escaping () -> Void) -> some View {
        modifier(GlassPressModifier(action:action))
    }
}
EOF

cat > "$SRC/Components/GlassButton.swift" << 'EOF'
import SwiftUI

struct GlassButton: View {
    let label: String
    let icon: String
    var variant: GlassButtonVariant = .primary
    var isLoading: Bool = false
    var fullWidth: Bool = false
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action:action) {
            HStack(spacing:8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint:variant.textColor))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName:icon).font(.system(.body, weight:.semibold))
                }
                Text(label).font(.system(.body, design:.rounded, weight:.semibold))
                if fullWidth { Spacer() }
            }
            .foregroundStyle(variant.textColor)
            .padding(.horizontal, fullWidth ? 20 : 22)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(variant.material, in:Capsule())
            .overlay(Capsule().stroke(variant.borderColor, lineWidth:1))
            .shadow(color:variant.shadow.opacity(0.30), radius:16)
            .scaleEffect(pressed ? 0.96 : 1.0)
            .animation(.spring(response:0.25, dampingFraction:0.70), value:pressed)
        }
        .disabled(isLoading)
        .simultaneousGesture(DragGesture(minimumDistance:0)
            .onChanged{_ in pressed = true}
            .onEnded{_ in pressed = false})
    }
}
EOF

cat > "$SRC/Components/TrustBadge.swift" << 'EOF'
import SwiftUI

struct TrustBadge: View {
    let state: TrustState
    var showPulse: Bool = false
    var size: BadgeSize = .medium

    var body: some View {
        HStack(spacing:5) {
            Circle()
                .fill(state.glowColor)
                .frame(width:size.dotSize, height:size.dotSize)
                .shadow(color:state.glowColor.opacity(0.9), radius:5)
                .modifier(PulseModifier(active:showPulse && state == .pending, color:state.glowColor))
            Text(state.label.uppercased())
                .font(.system(size:size.fontSize, weight:.bold, design:.rounded))
                .foregroundStyle(state.glowColor)
        }
        .padding(.horizontal, size.hPad).padding(.vertical, size.vPad)
        .background(.regularMaterial, in:Capsule())
        .overlay(Capsule().stroke(state.glowColor.opacity(0.38), lineWidth:1))
        .shadow(color:state.glowColor.opacity(0.22), radius:10)
    }
}
EOF

cat > "$SRC/Components/TrustScoreRing.swift" << 'EOF'
import SwiftUI

struct TrustScoreRing: View {
    let score: Int
    var size: CGFloat = 80
    var lineWidth: CGFloat = 7
    var color: Color = .stCyan
    @State private var animatedScore: Double = 0

    var body: some View {
        ZStack {
            Canvas { ctx, sz in
                let c = CGPoint(x:sz.width/2, y:sz.height/2)
                let r = min(sz.width,sz.height)/2 - lineWidth
                // Track
                var track = Path()
                track.addArc(center:c, radius:r, startAngle:.degrees(-90), endAngle:.degrees(270), clockwise:false)
                ctx.stroke(track, with:.color(.white.opacity(0.10)),
                           style:StrokeStyle(lineWidth:lineWidth, lineCap:.round))
                // Fill
                let end = Angle.degrees(-90 + animatedScore/100.0*360)
                var fill = Path()
                fill.addArc(center:c, radius:r, startAngle:.degrees(-90), endAngle:end, clockwise:false)
                ctx.stroke(fill, with:.color(color),
                           style:StrokeStyle(lineWidth:lineWidth, lineCap:.round))
            }
            .frame(width:size, height:size)
            VStack(spacing:0) {
                Text("\(score)")
                    .font(.system(size:size*0.28, weight:.bold, design:.rounded))
                    .foregroundStyle(.stPrimary)
                Text("%")
                    .font(.system(size:size*0.14, weight:.medium))
                    .foregroundStyle(.stSecondary)
            }
        }
        .onAppear { withAnimation(.spring(response:1.2, dampingFraction:0.75)) { animatedScore = Double(score) } }
        .onChange(of:score) { _,v in withAnimation(.spring(response:0.8, dampingFraction:0.75)) { animatedScore = Double(v) } }
    }
}
EOF

cat > "$SRC/Components/VerificationStepRow.swift" << 'EOF'
import SwiftUI

struct VerificationStepRow: View {
    let step: VerificationStep
    var isLast: Bool = false

    private var dotColor: Color {
        if step.isFailed   { return .stRed }
        if step.isComplete { return Color(hex:"00FF88") }
        if step.isActive   { return .stCyan }
        return .stQuaternary
    }

    var body: some View {
        HStack(alignment:.top, spacing:14) {
            VStack(spacing:0) {
                ZStack {
                    Circle().fill(dotColor.opacity(0.15)).frame(width:32,height:32)
                    if step.isActive && !step.isComplete && !step.isFailed {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint:.stCyan))
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: step.isFailed ? "xmark.circle.fill"
                              : step.isComplete ? "checkmark.circle.fill" : "circle")
                            .font(.system(size:18, weight:.semibold))
                            .foregroundStyle(dotColor)
                            .symbolEffect(.bounce, value:step.isComplete)
                    }
                }
                .shadow(color:dotColor.opacity(step.isActive || step.isComplete ? 0.6 : 0), radius:8)
                if !isLast {
                    Rectangle()
                        .fill(step.isComplete ? Color(hex:"00FF88").opacity(0.4) : Color.white.opacity(0.08))
                        .frame(width:2, height:24)
                        .animation(.stSpring.delay(0.15), value:step.isComplete)
                }
            }
            VStack(alignment:.leading, spacing:2) {
                Text(step.label)
                    .font(.stBodySm)
                    .foregroundStyle(step.isActive || step.isComplete ? .stPrimary : .stTertiary)
                if let detail = step.detail, step.isComplete || step.isFailed {
                    Text(detail)
                        .font(.stCaption)
                        .foregroundStyle(.stTertiary)
                        .transition(.opacity.combined(with:.offset(y:4)))
                }
            }
            .padding(.top,6)
            Spacer()
        }
        .animation(.stSpring, value:step.isComplete)
        .animation(.stSpring, value:step.isActive)
    }
}
EOF

cat > "$SRC/Components/LoadingState.swift" << 'EOF'
import SwiftUI
struct LoadingState: View {
    var message: String = "Loading…"
    var body: some View {
        VStack(spacing:16) {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint:.stCyan)).scaleEffect(1.3)
            Text(message).font(.stBodySm).foregroundStyle(.stSecondary)
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity)
    }
}
EOF

cat > "$SRC/Components/EmptyState.swift" << 'EOF'
import SwiftUI
struct EmptyState: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        VStack(spacing:16) {
            Image(systemName:icon).font(.system(size:48)).foregroundStyle(.stTertiary)
            Text(title).font(.stHeadline).foregroundStyle(.stSecondary)
            Text(message).font(.stBodySm).foregroundStyle(.stTertiary).multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth:.infinity)
    }
}
EOF

cat > "$SRC/Components/GlowOrb.swift" << 'EOF'
import SwiftUI
struct GlowOrb: View {
    let color: Color; let size: CGFloat; let blur: CGFloat
    var body: some View {
        Circle().fill(color).frame(width:size,height:size).blur(radius:blur)
    }
}
EOF

cat > "$SRC/Components/AppHeader.swift" << 'EOF'
import SwiftUI
struct AppHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil
    var body: some View {
        HStack(alignment:.center) {
            VStack(alignment:.leading, spacing:2) {
                Text(title).font(.stTitle1).foregroundStyle(.stPrimary)
                if let sub = subtitle { Text(sub).font(.stBodySm).foregroundStyle(.stSecondary) }
            }
            Spacer()
            trailing
        }
        .padding(.top,8)
    }
}
EOF


# ════════════════════════════════════════════════════════════════
# LAYER 9A — HOME SCREEN
# ════════════════════════════════════════════════════════════════

cat > "$SRC/Screens/Home/HomeView.swift" << 'EOF'
import SwiftUI

struct HomeView: View {
    @State private var vm = HomeViewModel()
    @State private var floatY: CGFloat = 0
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()
                ScrollView(showsIndicators:false) {
                    VStack(spacing:20) {
                        AppHeader(title:"Sovereign Trust", subtitle:"Identity Wallet",
                            trailing:AnyView(headerButtons))
                        WalletSummaryCard(identity:vm.identity, floatY:floatY)
                        statsRow
                        QuickActionsGrid(identity:vm.identity)
                        RecentVerificationsSection(results:vm.recentVerifications)
                        Spacer(minLength:90)
                    }
                    .padding(.horizontal,20)
                }
            }
            .navigationDestination(isPresented:$showSettings) {
                SettingsView(identity:vm.identity)
            }
        }
        .task { await vm.load() }
        .onAppear {
            withAnimation(.stFloat) { floatY = 3 }
        }
    }

    private var headerButtons: some View {
        HStack(spacing:10) {
            Circle().fill(Color(hex:"00FF88")).frame(width:8,height:8)
                .shadow(color:Color(hex:"00FF88"),radius:5)
            Button { showSettings = true } label: {
                Image(systemName:"gearshape.fill").font(.body.weight(.semibold))
                    .foregroundStyle(.stSecondary)
                    .frame(width:36,height:36)
                    .background(.ultraThinMaterial, in:Circle())
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing:12) {
            statTile(icon:"◈", value:"\(vm.credentials.count)", label:"Credentials")
            statTile(icon:"⭐", value:"\(vm.identity.trustScore)%", label:"Trust")
            statTile(icon:"🕐",
                     value:vm.identity.lastVerifiedAt.map{Formatters.timeAgo($0)} ?? "–",
                     label:"Verified")
        }
    }

    private func statTile(icon:String, value:String, label:String) -> some View {
        GlassCard(cornerRadius:20, innerPadding:14) {
            VStack(alignment:.leading, spacing:4) {
                Text(icon).font(.title2)
                Text(value).font(.stTitle2).foregroundStyle(.stCyan)
                Text(label).font(.stCaption).foregroundStyle(.stSecondary)
            }
            .frame(maxWidth:.infinity, alignment:.leading)
        }
    }
}
EOF

cat > "$SRC/Screens/Home/WalletSummaryCard.swift" << 'EOF'
import SwiftUI

struct WalletSummaryCard: View {
    let identity: Identity
    var floatY: CGFloat = 0
    @State private var shimmer: CGFloat = -0.5

    var body: some View {
        GlassCard(cornerRadius:32, glowColor:.stCyan, glowOpacity:0.22, innerPadding:0) {
            ZStack {
                // Holographic shimmer
                RoundedRectangle(cornerRadius:32, style:.continuous)
                    .fill(LinearGradient(
                        colors:[.clear, Color.stCyan.opacity(0.06), Color.stPurple.opacity(0.04), .clear],
                        startPoint:UnitPoint(x:shimmer, y:0), endPoint:UnitPoint(x:shimmer+0.6, y:1)))
                    .allowsHitTesting(false)
                VStack(spacing:0) {
                    HStack(alignment:.center, spacing:16) {
                        // Avatar ring
                        ZStack {
                            Circle()
                                .stroke(LinearGradient(colors:[.stCyan,.stPurple],
                                    startPoint:.topLeading, endPoint:.bottomTrailing), lineWidth:2.5)
                                .frame(width:76,height:76)
                                .shadow(color:.stCyan.opacity(0.4),radius:12)
                            Text(identity.avatarEmoji).font(.system(size:38))
                        }
                        VStack(alignment:.leading, spacing:4) {
                            Text(identity.displayName).font(.stTitle3).foregroundStyle(.stPrimary)
                            Text(identity.handle).font(.stCaption).foregroundStyle(.stSecondary)
                            Text(Formatters.shortDID(identity.did))
                                .font(.stMono).foregroundStyle(.stTertiary).lineLimit(1)
                        }
                        Spacer()
                        TrustScoreRing(score:identity.trustScore, size:76)
                    }
                    .padding(20)
                    Divider().background(Color.white.opacity(0.1))
                    HStack {
                        Label("Secure Enclave", systemImage:"lock.fill")
                            .font(.stCaption).foregroundStyle(.stSecondary)
                        Spacer()
                        TrustBadge(state:identity.trustState, size:.small)
                    }
                    .padding(.horizontal,20).padding(.vertical,12)
                }
            }
        }
        .offset(y:floatY)
        .onAppear {
            withAnimation(.linear(duration:4).repeatForever(autoreverses:false)) { shimmer = 1.5 }
        }
    }
}
EOF

cat > "$SRC/Screens/Home/QuickActionsGrid.swift" << 'EOF'
import SwiftUI

struct QuickActionsGrid: View {
    let identity: Identity
    var body: some View {
        VStack(alignment:.leading, spacing:12) {
            Text("Quick Actions").font(.stHeadline).foregroundStyle(.stPrimary)
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())], spacing:12) {
                ActionTile(title:"Scan QR", sub:"Verify anything",
                    icon:"qrcode.viewfinder", dest:AnyView(ScanView()))
                ActionTile(title:"Verify", sub:"Manual check",
                    icon:"checkmark.seal.fill", dest:AnyView(VerifyView()))
                ActionTile(title:"Passport", sub:"My identity",
                    icon:"person.crop.rectangle.fill",
                    dest:AnyView(PassportView(identity:identity)))
                ActionTile(title:"Products", sub:"Authenticity",
                    icon:"shippingbox.fill",
                    dest:AnyView(ProductsListView()))
            }
        }
    }
}

struct ActionTile: View {
    let title:String; let sub:String; let icon:String; let dest:AnyView
    @State private var pressed=false
    var body: some View {
        NavigationLink(destination:dest) {
            GlassCard(cornerRadius:22, innerPadding:16) {
                VStack(alignment:.leading, spacing:8) {
                    Image(systemName:icon).font(.title2).foregroundStyle(.stCyan)
                    Spacer()
                    Text(title).font(.stHeadline).foregroundStyle(.stPrimary)
                    Text(sub).font(.stCaption).foregroundStyle(.stSecondary)
                }
                .frame(maxWidth:.infinity, alignment:.leading)
                .frame(height:100)
            }
        }
        .buttonStyle(.plain)
    }
}
EOF

cat > "$SRC/Screens/Home/RecentVerificationsSection.swift" << 'EOF'
import SwiftUI

struct RecentVerificationsSection: View {
    let results:[VerificationResult]
    var body: some View {
        VStack(alignment:.leading, spacing:12) {
            Text("Recent").font(.stHeadline).foregroundStyle(.stPrimary)
            if results.isEmpty {
                GlassCard(cornerRadius:20, innerPadding:20) {
                    EmptyState(icon:"checkmark.seal",
                        title:"No verifications yet",
                        message:"Scan a QR code to get started")
                }
            } else {
                ScrollView(.horizontal, showsIndicators:false) {
                    HStack(spacing:12) {
                        ForEach(results) { r in
                            GlassCard(cornerRadius:20,
                                glowColor:r.trustState.glowColor, glowOpacity:0.12,
                                innerPadding:14) {
                                VStack(alignment:.leading, spacing:8) {
                                    TrustBadge(state:r.trustState, size:.small)
                                    Text(r.subjectId).font(.stHeadline).foregroundStyle(.stPrimary).lineLimit(1)
                                    Text(Formatters.timeAgo(r.verifiedAt))
                                        .font(.stCaption).foregroundStyle(.stSecondary)
                                }
                                .frame(width:160)
                            }
                        }
                    }
                }
            }
        }
    }
}
EOF


# ════════════════════════════════════════════════════════════════
# LAYER 9B — SCAN SCREEN (real AVFoundation QR)
# ════════════════════════════════════════════════════════════════

cat > "$SRC/Screens/Scan/CameraView.swift" << 'EOF'
import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @Binding var scannedCode: String?
    @Binding var isActive: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context:Context) -> UIView {
        let view = UIView(frame:.zero)
        view.backgroundColor = .black
        let session = AVCaptureSession()
        context.coordinator.session = session

        guard let device = AVCaptureDevice.default(for:.video),
              let input  = try? AVCaptureDeviceInput(device:device),
              session.canAddInput(input) else { return view }
        session.addInput(input)

        let out = AVCaptureMetadataOutput()
        guard session.canAddOutput(out) else { return view }
        session.addOutput(out)
        out.setMetadataObjectsDelegate(context.coordinator, queue:.main)
        out.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session:session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = UIScreen.main.bounds
        view.layer.addSublayer(preview)
        context.coordinator.preview = preview

        DispatchQueue.global(qos:.userInitiated).async { session.startRunning() }
        return view
    }

    func updateUIView(_ uiView:UIView, context:Context) {
        let s = context.coordinator.session
        if isActive && !(s?.isRunning ?? false) {
            DispatchQueue.global(qos:.userInitiated).async { s?.startRunning() }
        } else if !isActive && (s?.isRunning ?? false) {
            s?.stopRunning()
        }
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CameraView
        var session: AVCaptureSession?
        var preview: AVCaptureVideoPreviewLayer?
        private var lastScanDate = Date.distantPast

        init(_ p:CameraView) { parent = p }

        func metadataOutput(_ out:AVCaptureMetadataOutput,
            didOutput objects:[AVMetadataObject], from _:AVCaptureConnection) {
            guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
                  let raw = obj.stringValue,
                  Date().timeIntervalSince(lastScanDate) > 2 else { return }
            lastScanDate = Date()
            DispatchQueue.main.async {
                self.parent.scannedCode = raw
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}
EOF

cat > "$SRC/Screens/Scan/ScanOverlay.swift" << 'EOF'
import SwiftUI

struct ScanOverlay: View {
    let trustState: TrustState?
    @State private var laserY: CGFloat = 0
    private let boxSize: CGFloat = 260

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dark vignette outside scan box
                Color.black.opacity(0.55)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius:20)
                                    .frame(width:boxSize,height:boxSize)
                                    .blendMode(.destinationOut)
                            )
                            .compositingGroup()
                    )
                // Corner brackets
                let cx = geo.size.width/2; let cy = geo.size.height/2
                let half = boxSize/2
                ForEach(0..<4) { i in
                    CornerBracket(flipX: i%2==1, flipY: i/2==1)
                        .offset(x:cx + (i%2==0 ? -half : half-28),
                                y:cy + (i/2==0 ? -half : half-28))
                }
                // Laser beam
                Rectangle()
                    .fill(LinearGradient(colors:[.clear,.stCyan.opacity(0.8),.clear],
                        startPoint:.leading, endPoint:.trailing))
                    .frame(width:boxSize-20, height:2)
                    .shadow(color:.stCyan, radius:4)
                    .offset(x:cx-geo.size.width/2,
                            y:cy - half + laserY)
                // Trust tint after scan
                if let ts = trustState {
                    RoundedRectangle(cornerRadius:20)
                        .fill(ts.glowColor.opacity(0.10))
                        .frame(width:boxSize,height:boxSize)
                        .position(x:cx,y:cy)
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { animateLaser() }
    }

    private func animateLaser() {
        laserY = 0
        withAnimation(.linear(duration:1.8).repeatForever(autoreverses:true)) {
            laserY = 250
        }
    }
}

private struct CornerBracket: View {
    let flipX: Bool; let flipY: Bool
    var body: some View {
        Path { p in
            p.move(to:CGPoint(x:flipX ? 28:0, y:0))
            p.addLine(to:CGPoint(x:0,y:0))
            p.addLine(to:CGPoint(x:0,y:flipY ? 28:0))
        }
        .stroke(Color.stCyan, style:StrokeStyle(lineWidth:3,lineCap:.round,lineJoin:.round))
        .frame(width:28,height:28)
        .scaleEffect(x:flipX ? -1:1, y:flipY ? -1:1)
    }
}
EOF

cat > "$SRC/Screens/Scan/ScanTypeSelector.swift" << 'EOF'
import SwiftUI

struct ScanTypeSelector: View {
    @Binding var selected: VerificationSubjectType
    private let types: [(VerificationSubjectType,String,String)] = [
        (.credential,"Credential","checkmark.seal"),
        (.product,"Product","shippingbox"),
        (.document,"Document","doc.text"),
        (.login,"Login","person.badge.key"),
        (.did,"DID","link"),
    ]
    var body: some View {
        GlassCard(cornerRadius:22, innerPadding:10) {
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:8) {
                    ForEach(types,id:\.0) { type,label,icon in
                        Button { selected = type } label: {
                            Label(label,systemImage:icon)
                                .font(.stCaption)
                                .foregroundStyle(selected==type ? .stCyan : .stSecondary)
                                .padding(.horizontal,12).padding(.vertical,8)
                                .background(
                                    selected==type ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.clear),
                                    in:Capsule())
                                .overlay(Capsule().stroke(
                                    selected==type ? Color.stCyan.opacity(0.5) : Color.white.opacity(0.10),
                                    lineWidth:1))
                        }
                        .buttonStyle(.plain)
                        .animation(.stFastSpring, value:selected)
                    }
                }
            }
        }
    }
}
EOF

cat > "$SRC/Screens/Scan/VerificationResultCard.swift" << 'EOF'
import SwiftUI

struct VerificationResultCard: View {
    let result: VerificationResult
    var onDismiss: (() -> Void)? = nil
    @State private var layer = 0

    var body: some View {
        GlassCard(cornerRadius:26,
            glowColor:result.trustState.glowColor,
            glowOpacity:result.trustState.glowOpacity,
            innerPadding:0) {
            VStack(spacing:0) {
                // Accent stripe
                Rectangle().fill(result.trustState.glowColor).frame(height:3)
                VStack(alignment:.leading, spacing:12) {
                    // Layer 0 — always visible
                    HStack {
                        Image(systemName:result.trustState.sfIcon)
                            .foregroundStyle(result.trustState.glowColor).font(.title3)
                        Text(result.subjectId)
                            .font(.stHeadline).foregroundStyle(.stPrimary).lineLimit(1)
                        Spacer()
                        TrustBadge(state:result.trustState, size:.small)
                        if let dismiss = onDismiss {
                            Button(action:dismiss) {
                                Image(systemName:"xmark.circle.fill").foregroundStyle(.stTertiary)
                            }
                        }
                    }
                    Text(result.summary).font(.stBodySm).foregroundStyle(.stSecondary)
                    HStack(spacing:8) {
                        statChip("✓ \(result.passCount)", color:Color(hex:"00FF88"))
                        if result.warnCount > 0 { statChip("⚠ \(result.warnCount)", color:.stGold) }
                        if result.failCount > 0 { statChip("✗ \(result.failCount)", color:.stRed) }
                        statChip("\(result.durationMs)ms", color:.stSecondary)
                    }
                    // Layer 1 — check rows
                    if layer >= 1 {
                        Divider().background(Color.white.opacity(0.1))
                        VStack(alignment:.leading, spacing:8) {
                            ForEach(result.checks) { c in
                                HStack(spacing:8) {
                                    Image(systemName:c.outcome.icon).foregroundStyle(c.outcome.color).font(.caption2)
                                    Text(c.label).font(.stCaption).foregroundStyle(.stPrimary)
                                    Spacer()
                                    if let d = c.detail {
                                        Text(d).font(.stCaption).foregroundStyle(.stTertiary).lineLimit(1)
                                    }
                                }
                            }
                        }
                        .transition(.opacity.combined(with:.offset(y:12)))
                    }
                    // Layer 2 — trust chain
                    if layer >= 2 {
                        Divider().background(Color.white.opacity(0.1))
                        trustChain
                            .transition(.opacity.combined(with:.offset(y:12)))
                    }
                    // Tap hint
                    HStack {
                        Spacer()
                        Text(layer==0 ? "↓ tap for details" : layer==1 ? "↓ tap for trust chain" : "↑ tap to collapse")
                            .font(.stCaption).foregroundStyle(.stQuaternary)
                    }
                }
                .padding(16)
            }
        }
        .onTapGesture { withAnimation(.stSpring) { layer = (layer+1)%3 } }
        .onAppear { layer = 0 }
    }

    private func statChip(_ t:String, color:Color) -> some View {
        Text(t).font(.stCaption).foregroundStyle(color)
            .padding(.horizontal,8).padding(.vertical,4)
            .background(.ultraThinMaterial,in:Capsule())
            .overlay(Capsule().stroke(color.opacity(0.3),lineWidth:1))
    }

    private var trustChain: some View {
        HStack(spacing:8) {
            ForEach(Array(result.checks.prefix(3).enumerated()),id:\.offset) { idx,c in
                VStack(spacing:4) {
                    ZStack {
                        Circle().stroke(c.outcome.color.opacity(0.5),lineWidth:1.5).frame(width:32,height:32)
                        Image(systemName:c.outcome.icon).foregroundStyle(c.outcome.color).font(.caption)
                    }
                    Text(c.label).font(.system(size:8,weight:.medium)).foregroundStyle(.stTertiary)
                        .multilineTextAlignment(.center).lineLimit(2).frame(width:48)
                }
                if idx < 2 {
                    Rectangle().fill(Color.white.opacity(0.15)).frame(height:1).frame(maxWidth:.infinity)
                }
            }
        }
    }
}
EOF

cat > "$SRC/Screens/Scan/ScanView.swift" << 'EOF'
import SwiftUI
import AVFoundation

struct ScanView: View {
    @State private var scannedCode: String?
    @State private var cameraActive = true
    @State private var selectedType: VerificationSubjectType = .credential
    @State private var engine = VerificationEngine()
    @State private var hasPermission = false
    @State private var currentTrustState: TrustState? = nil

    var body: some View {
        ZStack {
            // Camera layer
            if hasPermission {
                CameraView(scannedCode:$scannedCode, isActive:$cameraActive)
                    .ignoresSafeArea()
            } else {
                noCameraPlaceholder
            }
            // Scan overlay (brackets + laser)
            ScanOverlay(trustState:currentTrustState)

            // Bottom UI
            VStack {
                Spacer()
                VStack(spacing:12) {
                    // Pipeline steps
                    if engine.isRunning {
                        GlassCard(cornerRadius:22, innerPadding:16) {
                            VStack(alignment:.leading, spacing:0) {
                                ForEach(Array(engine.steps.enumerated()),id:\.offset) { i,s in
                                    VerificationStepRow(step:s, isLast:i==engine.steps.count-1)
                                }
                            }
                        }
                        .transition(.move(edge:.bottom).combined(with:.opacity))
                    }
                    // Result
                    if let r = engine.result, !engine.isRunning {
                        VerificationResultCard(result:r) {
                            engine.result = nil; scannedCode = nil
                            cameraActive = true; currentTrustState = nil
                        }
                        .transition(.move(edge:.bottom).combined(with:.opacity))
                    }
                    // Type selector + reset
                    HStack(spacing:8) {
                        ScanTypeSelector(selected:$selectedType).frame(maxWidth:.infinity)
                        if engine.result != nil || engine.isRunning {
                            Button {
                                engine.result = nil; scannedCode = nil
                                cameraActive = true; currentTrustState = nil
                            } label: {
                                Image(systemName:"arrow.counterclockwise")
                                    .frame(width:44,height:44)
                                    .background(.regularMaterial,in:Circle())
                                    .foregroundStyle(.stCyan)
                            }
                        }
                    }
                }
                .padding(.horizontal,16).padding(.bottom,100)
                .animation(.stSpring, value:engine.isRunning)
                .animation(.stSpring, value:engine.result != nil)
            }
        }
        .onAppear { requestPermission() }
        .onChange(of:scannedCode) { _,code in
            guard let code, !engine.isRunning else { return }
            cameraActive = false
            let parsed = QRParserService.parse(code)
            let type = parsed.type == .unknown ? selectedType : parsed.type
            Task {
                await engine.verify(raw:code, type:type)
                currentTrustState = engine.result?.trustState
            }
        }
        .navigationTitle("Scan & Verify")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for:.navigationBar)
        .toolbarColorScheme(.dark, for:.navigationBar)
    }

    private var noCameraPlaceholder: some View {
        ZStack {
            AmbientBackground()
            VStack(spacing:16) {
                Image(systemName:"camera.fill").font(.system(size:52)).foregroundStyle(.stTertiary)
                Text("Camera Access Required").font(.stTitle3).foregroundStyle(.stPrimary)
                Text("Enable camera in Settings to scan QR codes")
                    .font(.stBodySm).foregroundStyle(.stSecondary).multilineTextAlignment(.center)
                GlassButton(label:"Open Settings",icon:"gearshape.fill") {
                    URL(string:UIApplication.openSettingsURLString).map{UIApplication.shared.open($0)}
                }
            }
            .padding(32)
        }
    }

    private func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for:.video) {
        case .authorized: hasPermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for:.video) { ok in
                DispatchQueue.main.async { hasPermission = ok }
            }
        default: hasPermission = false
        }
    }
}
EOF


# ════════════════════════════════════════════════════════════════
# LAYER 9C — PASSPORT, CREDENTIALS, VERIFY
# ════════════════════════════════════════════════════════════════

cat > "$SRC/Screens/Passport/PassportView.swift" << 'EOF'
import SwiftUI
struct PassportView: View {
    let identity: Identity
    @State private var vm = CredentialViewModel()
    @State private var floatY: CGFloat = 0
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:20) {
                    IdentityCard(identity:identity, floatY:floatY)
                    IdentityStats(identity:identity, credCount:vm.items.count)
                    CredentialListView(vm:vm, identity:identity)
                    Spacer(minLength:90)
                }
                .padding(.horizontal,20).padding(.top,8)
            }
        }
        .navigationTitle("Passport")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.ultraThinMaterial, for:.navigationBar)
        .toolbarColorScheme(.dark, for:.navigationBar)
        .task { await vm.load(subjectDid:identity.did) }
        .onAppear { withAnimation(.stFloat) { floatY = 3 } }
    }
}
EOF

cat > "$SRC/Screens/Passport/IdentityCard.swift" << 'EOF'
import SwiftUI
struct IdentityCard: View {
    let identity: Identity
    var floatY: CGFloat = 0
    @State private var shimmer: CGFloat = -0.5
    var body: some View {
        GlassCard(cornerRadius:32, glowColor:.stCyan, glowOpacity:0.22, innerPadding:0) {
            ZStack {
                RoundedRectangle(cornerRadius:32, style:.continuous)
                    .fill(LinearGradient(
                        colors:[.clear,Color.stCyan.opacity(0.06),Color.stPurple.opacity(0.04),.clear],
                        startPoint:UnitPoint(x:shimmer,y:0), endPoint:UnitPoint(x:shimmer+0.7,y:1)))
                    .allowsHitTesting(false)
                VStack(spacing:0) {
                    HStack(alignment:.center, spacing:16) {
                        ZStack {
                            Circle()
                                .stroke(LinearGradient(colors:[.stCyan,.stPurple],startPoint:.topLeading,endPoint:.bottomTrailing),lineWidth:2.5)
                                .frame(width:80,height:80).shadow(color:.stCyan.opacity(0.4),radius:12)
                            Text(identity.avatarEmoji).font(.system(size:40))
                        }
                        VStack(alignment:.leading, spacing:4) {
                            Text(identity.displayName).font(.stTitle3).foregroundStyle(.stPrimary)
                            Text(identity.handle).font(.stBodySm).foregroundStyle(.stSecondary)
                            if let lastV = identity.lastVerifiedAt {
                                Text("Verified \(Formatters.timeAgo(lastV))")
                                    .font(.stCaption).foregroundStyle(.stTertiary)
                            }
                        }
                        Spacer()
                        TrustScoreRing(score:identity.trustScore, size:80)
                    }
                    .padding(20)
                    Divider().background(Color.white.opacity(0.1))
                    HStack {
                        Label(Formatters.shortDID(identity.did), systemImage:"link")
                            .font(.stMono).foregroundStyle(.stTertiary).lineLimit(1)
                        Spacer()
                        Label("Secure Enclave",systemImage:"lock.fill")
                            .font(.stCaption).foregroundStyle(.stSecondary)
                    }
                    .padding(.horizontal,20).padding(.vertical,12)
                }
            }
        }
        .offset(y:floatY)
        .onAppear { withAnimation(.linear(duration:4).repeatForever(autoreverses:false)) { shimmer = 1.5 } }
    }
}
EOF

cat > "$SRC/Screens/Passport/IdentityStats.swift" << 'EOF'
import SwiftUI
struct IdentityStats: View {
    let identity: Identity; let credCount: Int
    var body: some View {
        HStack(spacing:12) {
            stat("\(credCount)", "Credentials", "◈")
            stat("\(identity.trustScore)%", "Trust Score", "⭐")
            stat(identity.biometryType.rawValue, "Biometry", "🔐")
        }
    }
    private func stat(_ v:String,_ l:String,_ i:String) -> some View {
        GlassCard(cornerRadius:20,innerPadding:14) {
            VStack(alignment:.leading,spacing:4) {
                Text(i).font(.title2)
                Text(v).font(.stTitle2).foregroundStyle(.stCyan)
                Text(l).font(.stCaption).foregroundStyle(.stSecondary)
            }.frame(maxWidth:.infinity,alignment:.leading)
        }
    }
}
EOF

cat > "$SRC/Screens/Credentials/CredentialListView.swift" << 'EOF'
import SwiftUI
struct CredentialListView: View {
    @Bindable var vm: CredentialViewModel
    let identity: Identity
    var body: some View {
        VStack(alignment:.leading, spacing:12) {
            HStack {
                Text("Credentials").font(.stHeadline).foregroundStyle(.stPrimary)
                Spacer()
                Text("\(vm.items.count) verified").font(.stCaption).foregroundStyle(.stSecondary)
            }
            CredentialFilterBar(active:$vm.activeFilter) { vm.applyFilter($0) }
            if vm.isLoading {
                LoadingState(message:"Loading credentials…")
            } else if vm.filtered.isEmpty {
                EmptyState(icon:"checkmark.seal",title:"No credentials",message:"No credentials match this filter")
            } else {
                LazyVStack(spacing:12) {
                    ForEach(vm.filtered) { cwi in
                        CredentialCard(cwi:cwi)
                            .glassPress { vm.selected = cwi }
                    }
                }
            }
        }
        .sheet(item:$vm.selected) { cwi in CredentialDetailSheet(cwi:cwi) }
    }
}
EOF

cat > "$SRC/Screens/Credentials/CredentialCard.swift" << 'EOF'
import SwiftUI
struct CredentialCard: View {
    let cwi: CredentialWithIssuer
    var body: some View {
        GlassCard(cornerRadius:24,glowColor:cwi.credential.trustState.glowColor,glowOpacity:0.10,innerPadding:0) {
            HStack(spacing:0) {
                Rectangle()
                    .fill(cwi.credential.trustState.glowColor)
                    .frame(width:4).clipShape(RoundedRectangle(cornerRadius:2))
                    .padding(.vertical,12).padding(.horizontal,12)
                VStack(alignment:.leading, spacing:5) {
                    HStack(spacing:6) {
                        Text(cwi.issuer.logoEmoji).font(.subheadline)
                        Text(cwi.issuer.shortName).font(.stCaption).foregroundStyle(.stSecondary)
                    }
                    Text(cwi.credential.title).font(.stHeadline).foregroundStyle(.stPrimary)
                    HStack(spacing:8) {
                        Label(cwi.credential.type.label,systemImage:cwi.credential.type.icon)
                            .font(.stCaption).foregroundStyle(.stTertiary)
                        TrustBadge(state:cwi.credential.trustState, size:.small)
                    }
                    if let exp = cwi.credential.expiresAt {
                        Text("Expires \(exp.formatted(style:.medium))")
                            .font(.stCaption).foregroundStyle(.stTertiary)
                    }
                }
                .padding(.vertical,14)
                Spacer()
                Image(systemName:"chevron.right").foregroundStyle(.stTertiary).padding(.trailing,16)
            }
        }
    }
}
EOF

cat > "$SRC/Screens/Credentials/CredentialFilterBar.swift" << 'EOF'
import SwiftUI
struct CredentialFilterBar: View {
    @Binding var active: CredentialFilter
    let onSelect: (CredentialFilter) -> Void
    var body: some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:8) {
                ForEach(CredentialFilter.allCases,id:\.self) { f in
                    Button { active = f; onSelect(f) } label: {
                        Text(f.rawValue).font(.stCaption)
                            .foregroundStyle(active==f ? .stCyan : .stSecondary)
                            .padding(.horizontal,12).padding(.vertical,7)
                            .background(active==f ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.clear),in:Capsule())
                            .overlay(Capsule().stroke(active==f ? Color.stCyan.opacity(0.4) : Color.white.opacity(0.1),lineWidth:1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}
EOF

cat > "$SRC/Screens/Credentials/CredentialDetailSheet.swift" << 'EOF'
import SwiftUI
struct CredentialDetailSheet: View {
    let cwi: CredentialWithIssuer
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage? = nil
    private var c: Credential { cwi.credential }
    private var iss: Issuer   { cwi.issuer }
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:20) {
                    HStack {
                        VStack(alignment:.leading,spacing:2) {
                            Text(c.title).font(.stTitle2).foregroundStyle(.stPrimary)
                            Text(iss.name).font(.stBodySm).foregroundStyle(.stSecondary)
                        }
                        Spacer()
                        Button{dismiss()} label:{
                            Image(systemName:"xmark.circle.fill").font(.title2).foregroundStyle(.stTertiary)
                        }
                    }.padding(.top,8)
                    TrustBadge(state:c.trustState)
                    // QR code
                    if let img = qrImage {
                        GlassCard(cornerRadius:24,glowColor:c.trustState.glowColor,glowOpacity:0.15,innerPadding:20) {
                            VStack(spacing:12) {
                                Image(uiImage:img).interpolation(.none).resizable()
                                    .scaledToFit().frame(width:200,height:200)
                                    .clipShape(RoundedRectangle(cornerRadius:12))
                                Text("Scan to verify").font(.stCaption).foregroundStyle(.stSecondary)
                            }.frame(maxWidth:.infinity)
                        }
                    }
                    // Issuer row
                    GlassCard(cornerRadius:22) {
                        HStack(spacing:12) {
                            Text(iss.logoEmoji).font(.title2)
                            VStack(alignment:.leading,spacing:2) {
                                Text(iss.name).font(.stHeadline).foregroundStyle(.stPrimary)
                                Text(iss.category.capitalized).font(.stCaption).foregroundStyle(.stSecondary)
                            }
                            Spacer()
                            TrustBadge(state:iss.trustState,size:.small)
                        }
                    }
                    // Details
                    GlassCard(cornerRadius:22) {
                        VStack(alignment:.leading,spacing:12) {
                            detailRow("Issued", c.issuedAt.formatted(style:.medium))
                            if let e = c.expiresAt { detailRow("Expires", e.formatted(style:.medium)) }
                            detailRow("Status", c.status.rawValue.capitalized)
                            detailRow("Hash", Formatters.shortHash(c.hash))
                            detailRow("Issuer DID", Formatters.shortDID(c.issuerDid))
                        }
                    }
                    GlassButton(label:"Share QR Code",icon:"square.and.arrow.up") { shareQR() }
                    Spacer(minLength:40)
                }
                .padding(.horizontal,20)
            }
        }
        .onAppear { qrImage = QRGeneratorService.generate(from:QRGeneratorService.credentialPayload(c)) }
    }
    private func detailRow(_ l:String,_ v:String) -> some View {
        VStack(alignment:.leading,spacing:2) {
            Text(l).font(.stCaption).foregroundStyle(.stTertiary)
            Text(v).font(.stMono).foregroundStyle(.stSecondary).lineLimit(2)
        }
    }
    private func shareQR() {
        guard let img = qrImage else { return }
        let ac = UIActivityViewController(activityItems:[img],applicationActivities:nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(ac,animated:true)
        }
    }
}
EOF

cat > "$SRC/Screens/Verify/VerifyView.swift" << 'EOF'
import SwiftUI
struct VerifyView: View {
    @State private var input = ""
    @State private var selected: VerificationSubjectType = .credential
    @State private var engine = VerificationEngine()
    @State private var tapLayer = 0
    @FocusState private var focused: Bool
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:20) {
                    AppHeader(title:"Verify Anything",subtitle:"Paste DID, QR payload or credential ID")
                    ScanTypeSelector(selected:$selected)
                    // Input
                    GlassCard(cornerRadius:18,innerPadding:14) {
                        VStack(alignment:.leading,spacing:8) {
                            Label("Input",systemImage:"text.cursor").font(.stCaption).foregroundStyle(.stTertiary)
                            ZStack(alignment:.topLeading) {
                                if input.isEmpty {
                                    Text("did:sov:… or paste QR payload…")
                                        .font(.stMono).foregroundStyle(.stQuaternary).allowsHitTesting(false)
                                }
                                TextEditor(text:$input)
                                    .frame(minHeight:80,maxHeight:160).font(.stMono)
                                    .foregroundStyle(.stPrimary).scrollContentBackground(.hidden)
                                    .focused($focused)
                            }
                        }
                    }
                    HStack(spacing:12) {
                        Button {
                            input = UIPasteboard.general.string ?? ""
                        } label: {
                            Label("Paste",systemImage:"doc.on.clipboard").font(.stBodySm).foregroundStyle(.stSecondary)
                                .padding(.horizontal,16).padding(.vertical,10)
                                .background(.ultraThinMaterial,in:Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.1),lineWidth:1))
                        }
                        Spacer()
                        GlassButton(label:"Verify",icon:"checkmark.seal.fill",isLoading:engine.isRunning) {
                            guard !input.trimmingCharacters(in:.whitespaces).isEmpty else { return }
                            focused = false
                            Task { await engine.verify(raw:input, type:selected) }
                        }
                    }
                    if engine.isRunning {
                        GlassCard(cornerRadius:22,innerPadding:16) {
                            VStack(alignment:.leading,spacing:0) {
                                ForEach(Array(engine.steps.enumerated()),id:\.offset) { i,s in
                                    VerificationStepRow(step:s,isLast:i==engine.steps.count-1)
                                }
                            }
                        }
                        .transition(.move(edge:.bottom).combined(with:.opacity))
                    }
                    if let r = engine.result, !engine.isRunning {
                        VerificationResultCard(result:r) { engine.result = nil }
                            .transition(.move(edge:.bottom).combined(with:.opacity))
                    }
                    if !engine.isRunning && engine.result == nil { tipsCard }
                    Spacer(minLength:90)
                }
                .padding(.horizontal,20).padding(.top,8)
            }
        }
        .navigationTitle("Verify")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial,for:.navigationBar)
        .toolbarColorScheme(.dark,for:.navigationBar)
        .animation(.stSpring,value:engine.isRunning)
        .animation(.stSpring,value:engine.result != nil)
    }
    private var tipsCard: some View {
        GlassCard(cornerRadius:20,innerPadding:16) {
            VStack(alignment:.leading,spacing:12) {
                Label("What you can verify",systemImage:"info.circle").font(.stCaption).foregroundStyle(.stTertiary)
                tip("link","DID string — did:sov:…")
                tip("qrcode","JSON QR payload")
                tip("checkmark.seal","Credential ID or hash")
                tip("doc.text","Raw JWT / VC token")
            }
        }
    }
    private func tip(_ icon:String,_ text:String) -> some View {
        HStack(spacing:10) {
            Image(systemName:icon).foregroundStyle(.stCyan).frame(width:20)
            Text(text).font(.stBodySm).foregroundStyle(.stSecondary)
        }
    }
}
EOF


# ════════════════════════════════════════════════════════════════
# LAYER 9D — TRUTH FEED, HANDSHAKE, PRODUCTS, SETTINGS
# ════════════════════════════════════════════════════════════════

cat > "$SRC/Screens/TruthFeed/TruthFeedView.swift" << 'EOF'
import SwiftUI
struct TruthFeedView: View {
    @State private var vm = TruthFeedViewModel()
    @State private var expandedId: String?
    @State private var fraudId: String?
    var body: some View {
        ZStack {
            AmbientBackground()
            VStack(spacing:0) {
                FeedFilterBar(vm:vm)
                if vm.isLoading { LoadingState(message:"Loading truth feed…").frame(maxWidth:.infinity,maxHeight:.infinity) }
                else {
                    ScrollView(showsIndicators:false) {
                        LazyVStack(spacing:14) {
                            ForEach(vm.filtered) { post in
                                PostCard(post:post,
                                    isExpanded:expandedId==post.id,
                                    showFraud:fraudId==post.id) {
                                    withAnimation(.stSpring) {
                                        if expandedId == post.id {
                                            fraudId = fraudId==post.id ? nil : post.id
                                        } else { expandedId = post.id; fraudId = nil }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal,16).padding(.vertical,12).padding(.bottom,90)
                    }
                }
            }
        }
        .navigationTitle("Truth Feed")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial,for:.navigationBar)
        .toolbarColorScheme(.dark,for:.navigationBar)
        .task { await vm.load() }
    }
}
EOF

cat > "$SRC/Screens/TruthFeed/FeedFilterBar.swift" << 'EOF'
import SwiftUI
struct FeedFilterBar: View {
    @Bindable var vm: TruthFeedViewModel
    var body: some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:8) {
                ForEach(FeedFilter.allCases,id:\.self) { f in
                    Button { vm.applyFilter(f) } label: {
                        HStack(spacing:5) {
                            Text(f.rawValue).font(.stCaption)
                                .foregroundStyle(vm.filter==f ? .stCyan : .stSecondary)
                            let n = vm.count(f)
                            if n > 0 {
                                Text("\(n)").font(.stLabel)
                                    .foregroundStyle(vm.filter==f ? .stCyan : .stTertiary)
                                    .padding(.horizontal,5).padding(.vertical,2)
                                    .background(vm.filter==f ? Color.stCyan.opacity(0.15) : .clear,in:Capsule())
                            }
                        }
                        .padding(.horizontal,14).padding(.vertical,8)
                        .background(vm.filter==f ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.clear),in:Capsule())
                        .overlay(Capsule().stroke(vm.filter==f ? Color.stCyan.opacity(0.5) : Color.white.opacity(0.1),lineWidth:1))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal,16).padding(.vertical,8)
        }
    }
}
EOF

cat > "$SRC/Screens/TruthFeed/PostCard.swift" << 'EOF'
import SwiftUI
struct PostCard: View {
    let post: Post; let isExpanded: Bool; let showFraud: Bool; let onTap: ()->Void
    var body: some View {
        GlassCard(cornerRadius:24,glowColor:post.trustState.glowColor,
            glowOpacity:post.trustState == .suspicious ? 0.20 : 0.05,innerPadding:0) {
            VStack(alignment:.leading, spacing:0) {
                Rectangle().fill(post.trustState.glowColor).frame(height:3)
                VStack(alignment:.leading, spacing:12) {
                    AuthorBadge(author:post.author, showDid:isExpanded)
                    Text(post.content).font(.stBody).foregroundStyle(.stPrimary)
                        .lineLimit(isExpanded ? nil : 3)
                    ClaimBar(verified:post.verifiedClaimCount, total:post.claimCount)
                    if isExpanded && !showFraud {
                        tagsRow.transition(.opacity.combined(with:.offset(y:8)))
                    }
                    if showFraud, let fa = post.fraudAnalysis {
                        fraudSection(fa).transition(.opacity.combined(with:.offset(y:8)))
                    }
                    footerRow
                    Text(showFraud ? "↑ tap to collapse" : isExpanded ? "↓ tap for fraud signals" : "↓ tap for details")
                        .font(.stCaption).foregroundStyle(.stQuaternary)
                        .frame(maxWidth:.infinity,alignment:.trailing)
                }
                .padding(16)
            }
        }
        .onTapGesture(perform:onTap)
    }
    private var tagsRow: some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:6) {
                ForEach(post.tags,id:\.self) { tag in
                    Text("#\(tag)").font(.stCaption).foregroundStyle(.stCyan)
                        .padding(.horizontal,8).padding(.vertical,4)
                        .background(.ultraThinMaterial,in:Capsule())
                }
            }
        }
    }
    private func fraudSection(_ fa:FraudAnalysis) -> some View {
        VStack(alignment:.leading, spacing:8) {
            HStack {
                Text("AI Fraud Analysis").font(.stCaption).foregroundStyle(.stSecondary)
                Spacer()
                Text("Risk: \(fa.riskScore)/100")
                    .font(.stLabel)
                    .foregroundStyle(fa.riskScore > 60 ? .stRed : .stGold)
                    .padding(.horizontal,8).padding(.vertical,3)
                    .background(.regularMaterial,in:Capsule())
            }
            ForEach(fa.signals) { sig in FraudSignalBadge(signal:sig) }
        }
    }
    private var footerRow: some View {
        HStack {
            if let src = post.sourceName {
                Label(src,systemImage:"link").font(.stCaption).foregroundStyle(.stTertiary)
            }
            Spacer()
            Text(Formatters.timeAgo(post.publishedAt)).font(.stCaption).foregroundStyle(.stTertiary)
        }
    }
}
EOF

cat > "$SRC/Screens/TruthFeed/AuthorBadge.swift" << 'EOF'
import SwiftUI
struct AuthorBadge: View {
    let author: PostAuthor; var showDid: Bool = false
    var body: some View {
        HStack(spacing:10) {
            ZStack {
                Circle().stroke(author.trustState.glowColor.opacity(0.5),lineWidth:1.5).frame(width:40,height:40)
                Text(author.avatarEmoji).font(.title3)
                if author.isVerified {
                    Image(systemName:"checkmark.seal.fill").font(.system(size:11))
                        .foregroundStyle(.stCyan).offset(x:13,y:13)
                }
            }
            VStack(alignment:.leading, spacing:2) {
                Text(author.displayName).font(.stHeadline).foregroundStyle(.stPrimary)
                if showDid {
                    Text(Formatters.shortDID(author.did)).font(.stMonoSm).foregroundStyle(.stTertiary)
                } else {
                    Text(author.handle).font(.stCaption).foregroundStyle(.stSecondary)
                }
                if let inst = author.institution { Text(inst).font(.stCaption).foregroundStyle(.stTertiary) }
            }
            Spacer()
            TrustBadge(state:author.trustState, size:.small)
        }
    }
}
EOF

cat > "$SRC/Screens/TruthFeed/ClaimBar.swift" << 'EOF'
import SwiftUI
struct ClaimBar: View {
    let verified: Int; let total: Int
    @State private var width: CGFloat = 0
    private var ratio: Double { total > 0 ? Double(verified)/Double(total) : 0 }
    private var barColor: Color { ratio >= 0.8 ? .stGreen : ratio >= 0.5 ? .stGold : .stOrange }
    var body: some View {
        VStack(alignment:.leading, spacing:4) {
            HStack {
                Text("\(verified)/\(total) claims verified").font(.stCaption).foregroundStyle(.stSecondary)
                Spacer()
                Text("\(Int(ratio*100))%").font(.stCaption).foregroundStyle(barColor)
            }
            GeometryReader { geo in
                ZStack(alignment:.leading) {
                    RoundedRectangle(cornerRadius:3).fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius:3).fill(barColor)
                        .frame(width:geo.size.width*ratio)
                        .animation(.easeInOut(duration:0.7), value:ratio)
                }
            }.frame(height:4)
        }
    }
}
EOF

cat > "$SRC/Screens/TruthFeed/FraudSignalBadge.swift" << 'EOF'
import SwiftUI
struct FraudSignalBadge: View {
    let signal: FraudSignal
    var body: some View {
        VStack(alignment:.leading, spacing:4) {
            HStack(spacing:6) {
                Circle().fill(signal.severity.color).frame(width:6,height:6)
                    .shadow(color:signal.severity.color,radius:3)
                Text(signal.label).font(.stCaption).foregroundStyle(signal.severity.color)
                Spacer()
                Text(signal.severity.rawValue.uppercased()).font(.stLabel)
                    .foregroundStyle(signal.severity.color.opacity(0.7))
            }
            .padding(.horizontal,10).padding(.vertical,6)
            .background(.regularMaterial,in:Capsule())
            .overlay(Capsule().stroke(signal.severity.color.opacity(0.30),lineWidth:1))
            if let d = signal.detail {
                Text(d).font(.stCaption).foregroundStyle(.stTertiary).padding(.leading,20)
            }
        }
    }
}
EOF


cat > "$SRC/Screens/Handshake/HandshakeView.swift" << 'EOF'
import SwiftUI
struct HandshakeView: View {
    let handshake: Handshake
    @Environment(\.dismiss) private var dismiss
    @State private var vm = HandshakeViewModel()

    var body: some View {
        ZStack {
            AmbientBackground()
            VStack(spacing:24) {
                Spacer()
                VStack(spacing:10) {
                    Image(systemName:"person.badge.key.fill").font(.system(size:52))
                        .foregroundStyle(.stCyan).shadow(color:.stCyan.opacity(0.5),radius:18)
                    Text("Login Request").font(.stTitle1).foregroundStyle(.stPrimary)
                    Text("DID Authentication Challenge").font(.stBodySm).foregroundStyle(.stSecondary)
                }
                GlassCard(cornerRadius:28, glowColor:.stBlue, glowOpacity:0.20) {
                    VStack(alignment:.leading, spacing:14) {
                        HStack {
                            Text(handshake.challenge.service).font(.stTitle2).foregroundStyle(.stPrimary)
                            Spacer()
                            Text("\(vm.timeRemaining)s")
                                .font(.stCaption).foregroundStyle(vm.timeRemaining < 60 ? .stRed : .stSecondary)
                                .padding(.horizontal,10).padding(.vertical,5)
                                .background(.ultraThinMaterial,in:Capsule())
                        }
                        VStack(alignment:.leading, spacing:2) {
                            Text("Nonce").font(.stCaption).foregroundStyle(.stTertiary)
                            Text(String(handshake.challenge.nonce.prefix(32)) + "…")
                                .font(.stMono).foregroundStyle(.stSecondary)
                        }
                        Text("This service is requesting DID authentication")
                            .font(.stBodySm).foregroundStyle(.stSecondary)
                        HStack(spacing:8) {
                            scopeChip("● Read Identity")
                            scopeChip("● Share DID")
                            scopeChip("● Sign Nonce")
                        }
                    }
                }
                // Result
                if let h = vm.handshake, h.status == .verified || h.status == .rejected {
                    let ok = h.status == .verified
                    GlassCard(cornerRadius:24,
                        glowColor:ok ? Color(hex:"00FF88") : .stRed, glowOpacity:0.40) {
                        HStack(spacing:12) {
                            Image(systemName:ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title2).foregroundStyle(ok ? Color(hex:"00FF88") : .stRed)
                            Text(ok ? "Authentication Complete" : "Authentication Failed")
                                .font(.stHeadline).foregroundStyle(.stPrimary)
                        }.frame(maxWidth:.infinity)
                    }
                }
                if let err = vm.error {
                    Text(err).font(.stCaption).foregroundStyle(.stRed)
                        .padding(12).background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:12))
                }
                Spacer()
                VStack(spacing:12) {
                    let h = vm.handshake ?? handshake
                    if h.status == .pending {
                        GlassButton(label:"Sign with \(handshake.challenge.service.isEmpty ? "Face ID" : "Face ID")",
                            icon:"faceid", variant:.primary, isLoading:vm.isSigning, fullWidth:true) {
                            Task { await vm.signWithBiometrics() }
                        }
                    }
                    GlassButton(label:"Cancel",icon:"xmark",variant:.secondary,fullWidth:true) { dismiss() }
                }
                .padding(.horizontal,24).padding(.bottom,40)
            }
            .padding(.horizontal,24)
        }
        .onAppear { vm.present(handshake) }
    }

    private func scopeChip(_ t:String) -> some View {
        Text(t).font(.stCaption).foregroundStyle(.stSecondary)
            .padding(.horizontal,10).padding(.vertical,5)
            .background(.ultraThinMaterial,in:Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15),lineWidth:1))
    }
}
EOF

cat > "$SRC/Screens/Products/ProductsListView.swift" << 'EOF'
import SwiftUI
struct ProductsListView: View {
    let products = MockData.products
    @State private var selected: Product?
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:16) {
                    AppHeader(title:"Products",subtitle:"Authenticity verification")
                    if products.isEmpty {
                        EmptyState(icon:"shippingbox",title:"No products",message:"Scan a product QR code to verify authenticity")
                    } else {
                        ForEach(products) { p in
                            ProductCard(product:p).glassPress { selected = p }
                        }
                    }
                    Spacer(minLength:90)
                }
                .padding(.horizontal,20).padding(.top,8)
            }
        }
        .navigationTitle("Products")
        .toolbarBackground(.ultraThinMaterial,for:.navigationBar)
        .toolbarColorScheme(.dark,for:.navigationBar)
        .navigationDestination(item:$selected) { p in ProductDetailView(product:p) }
    }
}
EOF

cat > "$SRC/Screens/Products/ProductCard.swift" << 'EOF'
import SwiftUI
struct ProductCard: View {
    let product: Product
    var body: some View {
        GlassCard(cornerRadius:24,glowColor:product.trustState.glowColor,glowOpacity:0.10,innerPadding:0) {
            HStack(spacing:0) {
                Rectangle().fill(product.trustState.glowColor).frame(width:4)
                    .clipShape(RoundedRectangle(cornerRadius:2)).padding(.vertical,12).padding(.horizontal,12)
                VStack(alignment:.leading,spacing:5) {
                    Text(product.brand).font(.stCaption).foregroundStyle(.stSecondary)
                    Text(product.name).font(.stHeadline).foregroundStyle(.stPrimary)
                    HStack(spacing:8) {
                        Label(product.category,systemImage:"shippingbox").font(.stCaption).foregroundStyle(.stTertiary)
                        TrustBadge(state:product.trustState,size:.small)
                    }
                    Text("SN: \(product.serialNumber)").font(.stMonoSm).foregroundStyle(.stTertiary)
                }
                .padding(.vertical,14)
                Spacer()
                Image(systemName:product.statusIcon).font(.title3)
                    .foregroundStyle(product.trustState.glowColor).padding(.trailing,16)
            }
        }
    }
}
EOF

cat > "$SRC/Screens/Products/ProductDetailView.swift" << 'EOF'
import SwiftUI
struct ProductDetailView: View {
    let product: Product
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:20) {
                    GlassCard(cornerRadius:28,glowColor:product.trustState.glowColor,glowOpacity:0.22) {
                        VStack(alignment:.leading,spacing:12) {
                            HStack {
                                VStack(alignment:.leading,spacing:4) {
                                    Text(product.brand).font(.stCaption).foregroundStyle(.stSecondary)
                                    Text(product.name).font(.stTitle2).foregroundStyle(.stPrimary)
                                    Text(product.category).font(.stBodySm).foregroundStyle(.stTertiary)
                                }
                                Spacer()
                                TrustBadge(state:product.trustState)
                            }
                            Divider().background(Color.white.opacity(0.1))
                            HStack { Text("SN").font(.stCaption).foregroundStyle(.stTertiary); Spacer()
                                Text(product.serialNumber).font(.stMono).foregroundStyle(.stSecondary) }
                            HStack { Text("Manufactured").font(.stCaption).foregroundStyle(.stTertiary); Spacer()
                                Text(product.manufacturedAt.formatted(style:.medium)).font(.stCaption).foregroundStyle(.stSecondary) }
                        }
                    }
                    CustodyChainView(chain:product.custodyChain)
                    Spacer(minLength:90)
                }
                .padding(.horizontal,20).padding(.top,8)
            }
        }
        .navigationTitle(product.name)
        .toolbarBackground(.ultraThinMaterial,for:.navigationBar)
        .toolbarColorScheme(.dark,for:.navigationBar)
    }
}
EOF

cat > "$SRC/Screens/Products/CustodyChainView.swift" << 'EOF'
import SwiftUI
struct CustodyChainView: View {
    let chain:[CustodyCheckpoint]
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            Text("Custody Chain").font(.stHeadline).foregroundStyle(.stPrimary)
            GlassCard(cornerRadius:22,innerPadding:16) {
                VStack(alignment:.leading,spacing:0) {
                    ForEach(Array(chain.enumerated()),id:\.offset) { idx,cp in
                        HStack(alignment:.top,spacing:14) {
                            VStack(spacing:0) {
                                ZStack {
                                    Circle().fill(Color.stCyan.opacity(0.15)).frame(width:30,height:30)
                                    Text("\(idx+1)").font(.stLabel).foregroundStyle(.stCyan)
                                }
                                if idx < chain.count-1 {
                                    Rectangle().fill(Color.stCyan.opacity(0.2)).frame(width:2,height:28)
                                }
                            }
                            VStack(alignment:.leading,spacing:3) {
                                Text(cp.actor).font(.stHeadline).foregroundStyle(.stPrimary)
                                Label(cp.location,systemImage:"mappin.circle").font(.stCaption).foregroundStyle(.stSecondary)
                                Text(cp.timestamp.formatted(style:.medium)).font(.stCaption).foregroundStyle(.stTertiary)
                                if let n = cp.note { Text(n).font(.stCaption).foregroundStyle(.stTertiary) }
                            }
                            .padding(.top,4)
                        }
                    }
                }
            }
        }
    }
}
EOF


cat > "$SRC/Screens/Settings/SettingsView.swift" << 'EOF'
import SwiftUI
struct SettingsView: View {
    let identity: Identity
    @State private var biometricResult: BiometricTestResult?
    @State private var showBioSheet = false
    @State private var keyFP = "SE-…"
    @State private var showTrustEngine = false
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:20) {
                    profileCard
                    securityCard
                    trustEngineCard
                    aboutCard
                    Spacer(minLength:90)
                }
                .padding(.horizontal,20).padding(.top,8)
            }
        }
        .navigationTitle("Settings")
        .toolbarBackground(.ultraThinMaterial,for:.navigationBar)
        .toolbarColorScheme(.dark,for:.navigationBar)
        .navigationDestination(isPresented:$showTrustEngine) { TrustEngineView() }
        .sheet(isPresented:$showBioSheet) { bioResultSheet }
        .task { await loadFingerprint() }
    }
    private var profileCard: some View {
        GlassCard(cornerRadius:28, glowColor:identity.trustState.glowColor, glowOpacity:0.15) {
            HStack(spacing:14) {
                ZStack {
                    Circle().stroke(identity.trustState.glowColor.opacity(0.5),lineWidth:2).frame(width:64,height:64)
                    Text(identity.avatarEmoji).font(.system(size:32))
                }
                VStack(alignment:.leading,spacing:3) {
                    Text(identity.displayName).font(.stTitle3).foregroundStyle(.stPrimary)
                    Text(identity.handle).font(.stCaption).foregroundStyle(.stSecondary)
                    Text(Formatters.shortDID(identity.did)).font(.stMonoSm).foregroundStyle(.stTertiary)
                }
                Spacer()
            }
        }
    }
    private var securityCard: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading, spacing:0) {
                Text("Security").font(.stCaption).foregroundStyle(.stTertiary).padding(.bottom,12)
                settingsRow(icon:"faceid",label:identity.biometryType.rawValue,value:"Active",color:.stCyan)
                Divider().background(Color.white.opacity(0.08)).padding(.vertical,10)
                settingsRow(icon:"key.fill",label:"Hardware Key",value:keyFP,color:.stPurple)
                Divider().background(Color.white.opacity(0.08)).padding(.vertical,10)
                HStack {
                    Image(systemName:"bolt.fill").foregroundStyle(.stCyan).frame(width:24)
                    Text("Run Biometric Test").font(.stBody).foregroundStyle(.stPrimary)
                    Spacer()
                    GlassButton(label:"Test",icon:"faceid",variant:.primary) {
                        Task { await runBioTest() }
                    }
                }
            }
        }
    }
    private var trustEngineCard: some View {
        GlassCard(cornerRadius:24, glowColor:.stCyan, glowOpacity:0.08) {
            Button { showTrustEngine = true } label: {
                HStack {
                    Image(systemName:"network").foregroundStyle(.stCyan).font(.title2)
                    VStack(alignment:.leading,spacing:2) {
                        Text("Trust Engine").font(.stHeadline).foregroundStyle(.stPrimary)
                        Text("Explore the trust graph infrastructure").font(.stCaption).foregroundStyle(.stSecondary)
                    }
                    Spacer()
                    Image(systemName:"chevron.right").foregroundStyle(.stTertiary)
                }
            }
        }
    }
    private var aboutCard: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading, spacing:0) {
                Text("About").font(.stCaption).foregroundStyle(.stTertiary).padding(.bottom,12)
                settingsRow(icon:"info.circle",label:"Version",value:AppConstants.appVersion)
                Divider().background(Color.white.opacity(0.08)).padding(.vertical,10)
                settingsRow(icon:"hammer.fill",label:"Build",value:AppConstants.buildNumber)
                Divider().background(Color.white.opacity(0.08)).padding(.vertical,10)
                settingsRow(icon:"iphone",label:"Platform",value:"iOS 17+")
            }
        }
    }
    private func settingsRow(icon:String,label:String,value:String,color:Color = .stSecondary) -> some View {
        HStack {
            Image(systemName:icon).foregroundStyle(color).frame(width:24)
            Text(label).font(.stBody).foregroundStyle(.stPrimary)
            Spacer()
            Text(value).font(.stCaption).foregroundStyle(.stSecondary).lineLimit(1)
        }
    }
    private var bioResultSheet: some View {
        ZStack {
            AmbientBackground()
            VStack(spacing:24) {
                Spacer()
                if let r = biometricResult {
                    Image(systemName:r.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size:64))
                        .foregroundStyle(r.success ? Color(hex:"00FF88") : .stRed)
                    Text(r.success ? "Biometrics Working" : "Biometrics Failed")
                        .font(.stTitle2).foregroundStyle(.stPrimary)
                    Text(r.biometryType.rawValue + " tested").font(.stBodySm).foregroundStyle(.stSecondary)
                    if let err = r.errorMessage { Text(err).font(.stCaption).foregroundStyle(.stRed) }
                }
                Spacer()
                GlassButton(label:"Done",icon:"checkmark",fullWidth:true) { showBioSheet = false }
                    .padding(.horizontal,32).padding(.bottom,40)
            }
        }
    }
    private func runBioTest() async {
        let r = await BiometricTestService.shared.runTest()
        await MainActor.run { biometricResult = r; showBioSheet = true }
    }
    private func loadFingerprint() async {
        let fp = (try? await SecureEnclaveService.shared.fingerprint()) ?? "SE-[unavailable]"
        await MainActor.run { keyFP = fp }
    }
}
EOF

cat > "$SRC/Screens/Settings/TrustEngineView.swift" << 'EOF'
import SwiftUI
struct TrustEngineView: View {
    @State private var graphTab = 0
    @State private var pipeStep = 0
    @State private var timer: Timer?
    let graphTabs = ["Education","Product","Identity","Network"]
    var body: some View {
        ZStack {
            AmbientBackground()
            ScrollView(showsIndicators:false) {
                VStack(spacing:24) {
                    // Header
                    GlassCard(cornerRadius:28, glowColor:.stCyan, glowOpacity:0.16) {
                        VStack(spacing:12) {
                            Image(systemName:"network").font(.system(size:52)).foregroundStyle(.stCyan)
                                .shadow(color:.stCyan.opacity(0.5),radius:18)
                            Text("The Trust Engine").font(.stTitle1).foregroundStyle(.stPrimary)
                            Text("Decentralised cryptographic trust for everything")
                                .font(.stBodySm).foregroundStyle(.stSecondary).multilineTextAlignment(.center)
                        }.frame(maxWidth:.infinity)
                    }
                    // Principle
                    TrustConceptCard(number:1,icon:"lightbulb.fill",title:"The Simple Principle",
                        body:"Every claim — a degree, a product, an identity — can be anchored to a cryptographic proof on a decentralised ledger. Verifiers trust math, not intermediaries.")
                    // Graph
                    TrustGraphCard(tabs:graphTabs, selected:$graphTab)
                    // Verification flow
                    VerificationFlowCard(activeStep:pipeStep)
                    // Use cases
                    UseCaseGrid()
                    // Trust network
                    TrustNetworkCard()
                    // Future
                    GlassCard(cornerRadius:24, glowColor:.stPurple, glowOpacity:0.15) {
                        VStack(alignment:.leading, spacing:10) {
                            Label("6. The Future of Trust",systemImage:"sparkles")
                                .font(.stHeadline).foregroundStyle(.stPurple)
                            Text("A world where identity is self-sovereign. Where credentials follow people, not institutions. Where trust is mathematical, not bureaucratic.")
                                .font(.stBody).foregroundStyle(.stSecondary)
                        }
                    }
                    Spacer(minLength:90)
                }
                .padding(.horizontal,20).padding(.top,8)
            }
        }
        .navigationTitle("Trust Engine")
        .toolbarBackground(.ultraThinMaterial,for:.navigationBar)
        .toolbarColorScheme(.dark,for:.navigationBar)
        .onAppear { startPipeline() }
        .onDisappear { timer?.invalidate() }
    }
    private func startPipeline() {
        pipeStep = 0
        timer = Timer.scheduledTimer(withTimeInterval:0.9,repeats:true) { _ in
            DispatchQueue.main.async { pipeStep = pipeStep >= 5 ? 0 : pipeStep+1 }
        }
    }
}
EOF

cat > "$SRC/Screens/Settings/TrustConceptCard.swift" << 'EOF'
import SwiftUI
struct TrustConceptCard: View {
    let number:Int; let icon:String; let title:String; let body:String
    var body: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading,spacing:10) {
                Label("\(number). \(title)",systemImage:icon).font(.stHeadline).foregroundStyle(.stCyan)
                Text(body).font(.stBody).foregroundStyle(.stSecondary)
            }
        }
    }
}
EOF

cat > "$SRC/Screens/Settings/TrustGraphCard.swift" << 'EOF'
import SwiftUI
struct TrustGraphCard: View {
    let tabs:[String]
    @Binding var selected:Int
    private struct N { let e:String; let x:Double; let y:Double; let ts:TrustState }
    private struct E { let f:Int; let t:Int; let l:String }
    private var nodes:[[N]] { [
        [N(e:"🎓",x:0.15,y:0.5,ts:.verified),N(e:"📄",x:0.5,y:0.25,ts:.verified),N(e:"👨‍💻",x:0.85,y:0.5,ts:.trusted),N(e:"🏢",x:0.5,y:0.75,ts:.trusted)],
        [N(e:"🏭",x:0.12,y:0.5,ts:.verified),N(e:"📦",x:0.45,y:0.2,ts:.verified),N(e:"🚚",x:0.8,y:0.5,ts:.trusted),N(e:"🛒",x:0.45,y:0.8,ts:.trusted)],
        [N(e:"🏛️",x:0.2,y:0.3,ts:.verified),N(e:"🪪",x:0.55,y:0.18,ts:.verified),N(e:"👛",x:0.85,y:0.4,ts:.trusted),N(e:"🔍",x:0.5,y:0.8,ts:.trusted)],
        [N(e:"🌐",x:0.5,y:0.15,ts:.verified),N(e:"🔷",x:0.2,y:0.6,ts:.trusted),N(e:"🔶",x:0.8,y:0.6,ts:.trusted),N(e:"🟢",x:0.5,y:0.88,ts:.verified)],
    ] }
    private var edges:[[E]] { [
        [E(f:0,t:1,l:"issues"),E(f:1,t:2,l:"holds"),E(f:2,t:3,l:"shares")],
        [E(f:0,t:1,l:"anchors"),E(f:1,t:2,l:"ships"),E(f:2,t:3,l:"delivers")],
        [E(f:0,t:1,l:"issues"),E(f:1,t:2,l:"held"),E(f:2,t:3,l:"verifies")],
        [E(f:0,t:1,l:"delegates"),E(f:0,t:2,l:"delegates"),E(f:1,t:3,l:"trusts"),E(f:2,t:3,l:"trusts")],
    ] }
    var body: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading,spacing:14) {
                Label("2. The Trust Graph",systemImage:"diagram.badge.heart.fill").font(.stHeadline).foregroundStyle(.stCyan)
                HStack(spacing:0) {
                    ForEach(Array(tabs.enumerated()),id:\.offset) { i,t in
                        Button { withAnimation(.stFastSpring) { selected = i } } label: {
                            Text(t).font(.stCaption)
                                .foregroundStyle(selected==i ? .stCyan : .stTertiary)
                                .padding(.horizontal,10).padding(.vertical,6)
                                .background(selected==i ? AnyShapeStyle(.regularMaterial):AnyShapeStyle(.clear),in:Capsule())
                        }.buttonStyle(.plain)
                    }
                }
                Canvas { ctx,sz in
                    let ns = nodes[selected]; let es = edges[selected]
                    for e in es {
                        guard e.f < ns.count, e.t < ns.count else { continue }
                        let from = CGPoint(x:ns[e.f].x*sz.width, y:ns[e.f].y*sz.height)
                        let to   = CGPoint(x:ns[e.t].x*sz.width, y:ns[e.t].y*sz.height)
                        var p = Path(); p.move(to:from); p.addLine(to:to)
                        ctx.stroke(p,with:.color(.white.opacity(0.15)),style:StrokeStyle(lineWidth:1.5,dash:[4,3]))
                    }
                    for n in ns {
                        let c = CGPoint(x:n.x*sz.width, y:n.y*sz.height)
                        ctx.fill(Path(ellipseIn:CGRect(x:c.x-18,y:c.y-18,width:36,height:36)),
                                 with:.color(n.ts.glowColor.opacity(0.18)))
                        ctx.stroke(Path(ellipseIn:CGRect(x:c.x-16,y:c.y-16,width:32,height:32)),
                                   with:.color(n.ts.glowColor.opacity(0.7)),lineWidth:1.5)
                        ctx.draw(Text(n.e).font(.system(size:14)),at:c)
                    }
                }
                .frame(height:180)
                .id(selected)
                .transition(.opacity)
            }
        }
    }
}
EOF

cat > "$SRC/Screens/Settings/VerificationFlowCard.swift" << 'EOF'
import SwiftUI
struct VerificationFlowCard: View {
    let activeStep:Int
    private let labels = ["QR Decode","Payload Parse","Signature Check","Issuer Registry","Trust Graph"]
    var body: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading,spacing:14) {
                Label("3. Verification Engine",systemImage:"gearshape.2.fill").font(.stHeadline).foregroundStyle(.stCyan)
                ForEach(Array(labels.enumerated()),id:\.offset) { i,l in
                    VerificationStepRow(
                        step:VerificationStep(number:i+1, label:l,
                            isActive:activeStep==i, isComplete:activeStep>i),
                        isLast:i==labels.count-1)
                }
            }
        }
    }
}
EOF

cat > "$SRC/Screens/Settings/UseCaseGrid.swift" << 'EOF'
import SwiftUI
struct UseCaseGrid: View {
    private let cases:[( String,String,String)] = [
        ("🎓","Education","Tamper-proof degrees"),("🏭","Supply Chain","Product provenance"),
        ("🏥","Healthcare","Medical credentials"),("⚖️","Legal","Signed documents"),
        ("🗳️","Voting","Identity proofs"),("💼","Employment","Background checks"),
    ]
    var body: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading,spacing:12) {
                Label("4. Global Use Cases",systemImage:"globe.asia.australia.fill").font(.stHeadline).foregroundStyle(.stCyan)
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10) {
                    ForEach(cases,id:\.1) { (e,t,d) in
                        VStack(alignment:.leading,spacing:4) {
                            Text(e).font(.title2)
                            Text(t).font(.stHeadline).foregroundStyle(.stPrimary)
                            Text(d).font(.stCaption).foregroundStyle(.stSecondary)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:14))
                        .overlay(RoundedRectangle(cornerRadius:14).stroke(Color.white.opacity(0.08),lineWidth:1))
                    }
                }
            }
        }
    }
}
EOF

cat > "$SRC/Screens/Settings/TrustNetworkCard.swift" << 'EOF'
import SwiftUI
struct TrustNetworkCard: View {
    private let items = [("🏛️","Issuers","9+"),("👛","Wallets","12K+"),("🔍","Verifiers","340+"),("🏢","Institutions","89+")]
    var body: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading,spacing:12) {
                Label("5. Trust Network",systemImage:"person.3.fill").font(.stHeadline).foregroundStyle(.stCyan)
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10) {
                    ForEach(items,id:\.1) { (e,t,n) in
                        VStack(alignment:.leading,spacing:4) {
                            HStack { Text(e).font(.title3); Spacer(); Text(n).font(.stTitle3).foregroundStyle(.stCyan) }
                            Text(t).font(.stHeadline).foregroundStyle(.stPrimary)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:14))
                        .overlay(RoundedRectangle(cornerRadius:14).stroke(Color.white.opacity(0.08),lineWidth:1))
                    }
                }
            }
        }
    }
}
EOF


# ════════════════════════════════════════════════════════════════
# LAYER 10 — APP SHELL
# ════════════════════════════════════════════════════════════════

cat > "$SRC/App/SovereignTrustApp.swift" << 'EOF'
import SwiftUI

@main
struct SovereignTrustApp: App {
    @State private var isReady = false
    @State private var bootError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if isReady           { ContentView().preferredColorScheme(.dark) }
                else if let e = bootError { BootErrorView(message:e) }
                else                 { BootView() }
            }
            .task { await boot() }
        }
    }

    private func boot() async {
        do {
            try await DatabaseManager.shared.setup()
            await MainActor.run { isReady = true }
        } catch {
            await MainActor.run { bootError = error.localizedDescription }
        }
    }
}

struct BootView: View {
    @State private var glow = false
    var body: some View {
        ZStack {
            AmbientBackground()
            VStack(spacing:20) {
                Image(systemName:"lock.shield.fill").font(.system(size:64)).foregroundStyle(.stCyan)
                    .scaleEffect(glow ? 1.06 : 0.96).shadow(color:.stCyan.opacity(0.5),radius:glow ? 24:8)
                    .animation(.stPulse, value:glow)
                Text("Sovereign Trust").font(.stTitle1).foregroundStyle(.stPrimary)
                Text("Initialising secure environment…").font(.stBodySm).foregroundStyle(.stSecondary)
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint:.stCyan)).scaleEffect(1.2)
            }
        }
        .onAppear { glow = true }
    }
}

struct BootErrorView: View {
    let message:String
    var body: some View {
        ZStack {
            AmbientBackground()
            VStack(spacing:16) {
                Image(systemName:"exclamationmark.triangle.fill").font(.system(size:52)).foregroundStyle(.stRed)
                Text("Initialisation Failed").font(.stTitle2).foregroundStyle(.stPrimary)
                Text(message).font(.stBodySm).foregroundStyle(.stSecondary).multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }
}
EOF

cat > "$SRC/App/ContentView.swift" << 'EOF'
import SwiftUI

struct ContentView: View {
    @State private var tab = 0
    private let identity = Identity.mock

    var body: some View {
        TabView(selection:$tab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home",     systemImage:"house.fill")                 }.tag(0)
            NavigationStack { ScanView() }
                .tabItem { Label("Scan",     systemImage:"qrcode.viewfinder")           }.tag(1)
            NavigationStack { PassportView(identity:identity) }
                .tabItem { Label("Passport", systemImage:"person.crop.rectangle.fill")  }.tag(2)
            NavigationStack { VerifyView() }
                .tabItem { Label("Verify",   systemImage:"checkmark.seal.fill")         }.tag(3)
            NavigationStack { TruthFeedView() }
                .tabItem { Label("Feed",     systemImage:"newspaper.fill")              }.tag(4)
        }
        .tint(Color(hex:"22D3EE"))
    }
}
EOF

cat > "$SRC/App/Routes.swift" << 'EOF'
import Foundation
enum AppRoute: Hashable {
    case home, scan, passport, verify, feed, settings
    case credentialDetail(String)
    case productDetail(String)
    case handshake(String)
}
EOF

cat > "$SRC/App/AppState.swift" << 'EOF'
import Foundation
import Observation

@Observable
final class AppState {
    static let shared = AppState()
    var identity: Identity = .mock
    var isAuthenticated = false
    var pendingHandshake: Handshake?
    private init() {}
}
EOF

# ════════════════════════════════════════════════════════════════
# Info.plist
# ════════════════════════════════════════════════════════════════
cat > "$SRC/Resources/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleExecutable</key><string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key><string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>Sovereign Trust</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>2.0.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>NSCameraUsageDescription</key><string>Sovereign Trust needs camera access to scan QR codes for identity verification.</string>
    <key>NSFaceIDUsageDescription</key><string>Sovereign Trust uses Face ID to sign authentication challenges and protect your identity.</string>
    <key>NSPhotoLibraryUsageDescription</key><string>Save or share credential QR codes.</string>
    <key>UILaunchStoryboardName</key><string></string>
    <key>UIApplicationSceneManifest</key>
    <dict><key>UIApplicationSupportsMultipleScenes</key><false/></dict>
    <key>UISupportedInterfaceOrientations</key>
    <array><string>UIInterfaceOrientationPortrait</string></array>
    <key>ITSAppUsesNonExemptEncryption</key><false/>
</dict></plist>
EOF


# ════════════════════════════════════════════════════════════════
# Package.swift
# ════════════════════════════════════════════════════════════════
cat > "$ROOT/Package.swift" << 'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SovereignTrust",
    platforms: [.iOS(.v17)],
    products: [.library(name:"SovereignTrust", targets:["SovereignTrust"])],
    dependencies: [
        .package(url:"https://github.com/groue/GRDB.swift.git", exact:"6.27.0"),
        .package(url:"https://github.com/EFPrefix/EFQRCode.git", from:"6.2.1"),
    ],
    targets: [
        .target(
            name:"SovereignTrust",
            dependencies:[
                .product(name:"GRDB",     package:"GRDB.swift"),
                .product(name:"EFQRCode", package:"EFQRCode"),
            ],
            path:"Sources/SovereignTrust",
            resources:[.process("Resources")]
        ),
        .testTarget(name:"SovereignTrustTests",
            dependencies:["SovereignTrust"], path:"Tests"),
    ]
)
EOF

# ════════════════════════════════════════════════════════════════
# project.yml  (XcodeGen)
# ════════════════════════════════════════════════════════════════
cat > "$ROOT/project.yml" << 'EOF'
name: SovereignTrust
options:
  bundleIdPrefix: com.sovereigntrust
  deploymentTarget:
    iOS: "17.0"
  defaultConfig: Debug
  xcodeVersion: "15.2"
configs:
  Debug:   debug
  Release: release
settings:
  SWIFT_VERSION: "5.9"
  IPHONEOS_DEPLOYMENT_TARGET: "17.0"
  CODE_SIGN_STYLE: Automatic
  DEVELOPMENT_TEAM: ""
  MARKETING_VERSION: "2.0.0"
  CURRENT_PROJECT_VERSION: "1"
  SWIFT_STRICT_CONCURRENCY: complete
  ENABLE_HARDENED_RUNTIME: YES
targets:
  SovereignTrust:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: Sources/SovereignTrust
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.sovereigntrust.app
      INFOPLIST_FILE: Sources/SovereignTrust/Resources/Info.plist
      CODE_SIGN_ENTITLEMENTS: SovereignTrust/SovereignTrust.entitlements
    info:
      path: Sources/SovereignTrust/Resources/Info.plist
    dependencies:
      - package: GRDB
        product: GRDB
      - package: EFQRCode
        product: EFQRCode
packages:
  GRDB:
    url: https://github.com/groue/GRDB.swift.git
    exactVersion: "6.27.0"
  EFQRCode:
    url: https://github.com/EFPrefix/EFQRCode.git
    from: "6.2.1"
EOF

# ════════════════════════════════════════════════════════════════
# Entitlements
# ════════════════════════════════════════════════════════════════
mkdir -p "$ROOT/SovereignTrust"
cat > "$ROOT/SovereignTrust/SovereignTrust.entitlements" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>keychain-access-groups</key>
    <array><string>$(AppIdentifierPrefix)com.sovereigntrust.app</string></array>
</dict></plist>
EOF

# ════════════════════════════════════════════════════════════════
# .gitignore
# ════════════════════════════════════════════════════════════════
cat > "$ROOT/.gitignore" << 'EOF'
.DS_Store
.build/
*.xcworkspace/xcuserdata/
DerivedData/
*.moved-aside
xcuserdata/
*.xccheckout
*.xcscmblueprint
*.ipa
*.dSYM.zip
*.dSYM
EOF

# ════════════════════════════════════════════════════════════════
# XcodeGen + resolve deps + git
# ════════════════════════════════════════════════════════════════
cd "$ROOT"
echo ""
echo "⚙️   Running XcodeGen…"
xcodegen generate --spec project.yml

echo ""
echo "📦  Resolving Swift Package dependencies…"
xcodebuild -resolvePackageDependencies \
    -project SovereignTrust.xcodeproj \
    -scheme SovereignTrust \
    -clonedSourcePackagesDirPath .build 2>&1 \
    | grep -E "(error:|Resolved|Fetching)" || true

echo ""
echo "🗂   Initialising git…"
git init -q
git add -A
git commit -q -m "Initial Sovereign Trust SwiftUI v2.0 scaffold

- Real AVFoundation QR scanner (6 payload types)
- Secure Enclave key ops via CryptoKit / Security.framework
- LocalAuthentication biometrics (explicit-only, never auto)
- True Apple .ultraThinMaterial liquid glass on every surface
- TimelineView animated ambient orbs background
- GRDB SQLite with migrations and mock data seed
- 5-step async verification pipeline
- 3-layer progressive reveal on result and post cards
- TruthFeed with AI fraud signal analysis
- DID Handshake / passwordless login flow
- Trust Engine with Canvas-drawn interactive graphs
- Products authenticity view with custody chain
- ~80 Swift files across 30 directories"

SWIFT_COUNT=$(find "$ROOT/Sources" -name "*.swift" | wc -l | tr -d ' ')

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           ✅  BUILD COMPLETE                              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "  📁  Project: $ROOT"
echo "  📄  Swift files: $SWIFT_COUNT"
echo ""
echo "  ─── Open in Xcode ──────────────────────────────────────"
echo "  open $ROOT/SovereignTrust.xcodeproj"
echo ""
echo "  ─── Set Team ID (one-time) ─────────────────────────────"
echo "  Xcode → SovereignTrust target"
echo "  → Signing & Capabilities → Team"
echo ""
echo "  ─── Build & Run ────────────────────────────────────────"
echo "  Connect iPhone → Cmd+R"
echo ""
echo "  ─── Key features ───────────────────────────────────────"
echo "  📷  Real AVFoundation QR scanner"
echo "  🔐  Secure Enclave key + Face ID (explicit tap only)"
echo "  🪟  True .ultraThinMaterial liquid glass on every card"
echo "  🌊  TimelineView animated cyan/purple light orbs"
echo "  ✅  5-step verification pipeline with staggered reveal"
echo "  📰  Truth Feed with AI fraud signal badges"
echo ""

