import SwiftUI
import AVFoundation

// MARK: – Product Scanner Sheet
// Lightweight sheet that re-uses existing CameraView for QR scanning.

struct ProductScannerSheet: View {
    let onScan: (String) -> Void
    @State private var scannedCode: String?
    @State private var cameraActive = true
    @State private var hasPermission = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if hasPermission {
                CameraView(scannedCode: $scannedCode, isActive: $cameraActive)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill").font(.system(size: 52)).foregroundStyle(.gray)
                    Text("Camera Access Required").font(.title3).foregroundStyle(.white)
                    Button("Open Settings") {
                        URL(string: UIApplication.openSettingsURLString).map { UIApplication.shared.open($0) }
                    }
                    .foregroundStyle(Color.stCyan)
                }
            }

            // Overlay
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title).foregroundStyle(.white.opacity(0.7))
                            .padding()
                    }
                }
                Spacer()

                // Scan frame
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.stCyan.opacity(0.5), lineWidth: 2)
                    .frame(width: 240, height: 240)
                    .shadow(color: Color.stCyan.opacity(0.3), radius: 10)

                Spacer()

                VStack(spacing: 8) {
                    Text("Scan Product QR Code").font(.headline).foregroundStyle(.white)
                    Text("Point camera at the product's QR code")
                        .font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear { requestPermission() }
        .onChange(of: scannedCode) { _, code in
            guard let code else { return }
            cameraActive = false
            onScan(code)
        }
    }

    private func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: hasPermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { ok in
                DispatchQueue.main.async { hasPermission = ok }
            }
        default: hasPermission = false
        }
    }
}
