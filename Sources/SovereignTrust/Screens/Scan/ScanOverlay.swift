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
                    .shadow(color: Color.stCyan, radius:4)
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
