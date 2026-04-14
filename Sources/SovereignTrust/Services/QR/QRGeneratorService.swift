import UIKit
import CoreImage.CIFilterBuiltins
import CryptoKit

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

    static func productPayload(_ product: Product, manufacturerDid: String? = nil, at date: Date = Date()) -> String {
        let did = manufacturerDid ?? product.manufacturerDid
        let ts = "\(Int(date.timeIntervalSince1970))"
        let nonce = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let hash = dynamicProductHash(
            id: product.id,
            serial: product.serialNumber,
            did: did,
            nonce: nonce,
            ts: ts
        )
        let p: [String: Any] = [
            "v": 1,
            "t": "product",
            "id": product.id,
            "did": did,
            "iss": did,
            "hash": hash,
            "ts": ts,
            "nonce": nonce,
            "serial": product.serialNumber,
            "brand": product.brand,
            "title": product.name
        ]
        let data = try? JSONSerialization.data(withJSONObject: p)
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? product.id
    }

    private static func dynamicProductHash(id: String, serial: String, did: String, nonce: String, ts: String) -> String {
        sha256Hex("\(id)|\(serial)|\(did)|\(nonce)|\(ts)")
    }

    private static func sha256Hex(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
