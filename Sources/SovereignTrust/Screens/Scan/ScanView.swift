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
                                    .foregroundStyle(Color.stCyan)
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
                Image(systemName:"camera.fill").font(.system(size:52)).foregroundStyle(Color.stTertiary)
                Text("Camera Access Required").font(.stTitle3).foregroundStyle(Color.stPrimary)
                Text("Enable camera in Settings to scan QR codes")
                    .font(.stBodySm).foregroundStyle(Color.stSecondary).multilineTextAlignment(.center)
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
