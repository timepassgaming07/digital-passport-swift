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
