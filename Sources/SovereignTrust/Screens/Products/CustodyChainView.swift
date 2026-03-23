import SwiftUI
struct CustodyChainView: View {
    let chain:[CustodyCheckpoint]
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            Text("Custody Chain").font(.stHeadline).foregroundStyle(Color.stPrimary)
            GlassCard(cornerRadius:22,innerPadding:16) {
                VStack(alignment:.leading,spacing:0) {
                    ForEach(Array(chain.enumerated()),id:\.offset) { idx,cp in
                        HStack(alignment:.top,spacing:14) {
                            VStack(spacing:0) {
                                ZStack {
                                    Circle().fill(Color.stCyan.opacity(0.15)).frame(width:30,height:30)
                                    Text("\(idx+1)").font(.stLabel).foregroundStyle(Color.stCyan)
                                }
                                if idx < chain.count-1 {
                                    Rectangle().fill(Color.stCyan.opacity(0.2)).frame(width:2,height:28)
                                }
                            }
                            VStack(alignment:.leading,spacing:3) {
                                Text(cp.actor).font(.stHeadline).foregroundStyle(Color.stPrimary)
                                Label(cp.location,systemImage:"mappin.circle").font(.stCaption).foregroundStyle(Color.stSecondary)
                                Text(cp.timestamp.formatted(style:.medium)).font(.stCaption).foregroundStyle(Color.stTertiary)
                                if let n = cp.note { Text(n).font(.stCaption).foregroundStyle(Color.stTertiary) }
                            }
                            .padding(.top,4)
                        }
                    }
                }
            }
        }
    }
}
