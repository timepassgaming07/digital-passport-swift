import SwiftUI
struct ClaimBar: View {
    let verified: Int; let total: Int
    @State private var width: CGFloat = 0
    private var ratio: Double { total > 0 ? Double(verified)/Double(total) : 0 }
    private var barColor: Color { ratio >= 0.8 ? Color.stGreen : ratio >= 0.5 ? Color.stGold : Color.stOrange }
    var body: some View {
        VStack(alignment:.leading, spacing:4) {
            HStack {
                Text("\(verified)/\(total) claims verified").font(.stCaption).foregroundStyle(Color.stSecondary)
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
