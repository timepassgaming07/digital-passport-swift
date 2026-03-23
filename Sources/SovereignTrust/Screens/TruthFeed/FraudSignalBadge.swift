import SwiftUI
struct FraudSignalBadge: View {
    let signal: FraudSignal
    var body: some View {
        VStack(alignment:.leading, spacing:4) {
            HStack(spacing:6) {
                Circle().fill(signal.severity.color).frame(width:6,height:6)
                    .shadow(color:signal.severity.color,radius:3)
                Text(signal.label).font(.stCaption).foregroundStyle(signal.severity.color)
                Spacer()
                Text(signal.severity.rawValue.uppercased()).font(.stLabel)
                    .foregroundStyle(signal.severity.color.opacity(0.7))
            }
            .padding(.horizontal,10).padding(.vertical,6)
            .background(.regularMaterial,in:Capsule())
            .overlay(Capsule().stroke(signal.severity.color.opacity(0.30),lineWidth:1))
            if let d = signal.detail {
                Text(d).font(.stCaption).foregroundStyle(Color.stTertiary).padding(.leading,20)
            }
        }
    }
}
