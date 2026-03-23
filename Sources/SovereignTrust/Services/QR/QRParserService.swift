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
