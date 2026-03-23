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
