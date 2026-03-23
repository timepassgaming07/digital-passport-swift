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
                    .foregroundStyle(Color.stPrimary)
                Text("%")
                    .font(.system(size:size*0.14, weight:.medium))
                    .foregroundStyle(Color.stSecondary)
            }
        }
        .onAppear { withAnimation(.spring(response:1.2, dampingFraction:0.75)) { animatedScore = Double(score) } }
        .onChange(of:score) { _,v in withAnimation(.spring(response:0.8, dampingFraction:0.75)) { animatedScore = Double(v) } }
    }
}
