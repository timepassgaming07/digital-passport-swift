import SwiftUI
struct GlowOrb: View {
    let color: Color; let size: CGFloat; let blur: CGFloat
    var body: some View {
        Circle().fill(color).frame(width:size,height:size).blur(radius:blur)
    }
}
