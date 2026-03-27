import SwiftUI
struct TrustGraphCard: View {
    let tabs:[String]
    @Binding var selected:Int
    private struct N { let e:String; let x:Double; let y:Double; let ts:TrustState }
    private struct E { let f:Int; let t:Int; let l:String }
    private var nodes:[[N]] { [
        [N(e:"🎓",x:0.15,y:0.5,ts:.verified),N(e:"📄",x:0.5,y:0.25,ts:.verified),N(e:"👨‍💻",x:0.85,y:0.5,ts:.trusted),N(e:"🏢",x:0.5,y:0.75,ts:.trusted)],
        [N(e:"🏭",x:0.12,y:0.5,ts:.verified),N(e:"📦",x:0.45,y:0.2,ts:.verified),N(e:"🚚",x:0.8,y:0.5,ts:.trusted),N(e:"🛒",x:0.45,y:0.8,ts:.trusted)],
        [N(e:"🏛️",x:0.2,y:0.3,ts:.verified),N(e:"🪪",x:0.55,y:0.18,ts:.verified),N(e:"👛",x:0.85,y:0.4,ts:.trusted),N(e:"🔍",x:0.5,y:0.8,ts:.trusted)],
        [N(e:"🌐",x:0.5,y:0.15,ts:.verified),N(e:"🔷",x:0.2,y:0.6,ts:.trusted),N(e:"🔶",x:0.8,y:0.6,ts:.trusted),N(e:"🟢",x:0.5,y:0.88,ts:.verified)],
    ] }
    private var edges:[[E]] { [
        [E(f:0,t:1,l:"issues"),E(f:1,t:2,l:"holds"),E(f:2,t:3,l:"shares")],
        [E(f:0,t:1,l:"anchors"),E(f:1,t:2,l:"ships"),E(f:2,t:3,l:"delivers")],
        [E(f:0,t:1,l:"issues"),E(f:1,t:2,l:"held"),E(f:2,t:3,l:"verifies")],
        [E(f:0,t:1,l:"delegates"),E(f:0,t:2,l:"delegates"),E(f:1,t:3,l:"trusts"),E(f:2,t:3,l:"trusts")],
    ] }
    var body: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading,spacing:14) {
                Label("2. The Trust Graph",systemImage:"diagram.badge.heart.fill").font(.stHeadline).foregroundStyle(Color.stCyan)
                HStack(spacing:0) {
                    ForEach(Array(tabs.enumerated()),id:\.offset) { i,t in
                        Button { withAnimation(.stFastSpring) { selected = i } } label: {
                            Text(t).font(.stCaption)
                                .foregroundStyle(selected==i ? Color.stCyan : Color.stTertiary)
                                .padding(.horizontal,10).padding(.vertical,6)
                                .background { if selected==i { Capsule().fill(.clear).glassEffect(.regular, in: .capsule) } }
                                .shadow(color: selected==i ? Color.stCyan.opacity(0.20) : .clear, radius: 6)
                        }.buttonStyle(.plain)
                    }
                }
                Canvas { ctx,sz in
                    let ns = nodes[selected]; let es = edges[selected]
                    for e in es {
                        guard e.f < ns.count, e.t < ns.count else { continue }
                        let from = CGPoint(x:ns[e.f].x*sz.width, y:ns[e.f].y*sz.height)
                        let to   = CGPoint(x:ns[e.t].x*sz.width, y:ns[e.t].y*sz.height)
                        var p = Path(); p.move(to:from); p.addLine(to:to)
                        ctx.stroke(p,with:.color(.white.opacity(0.15)),style:StrokeStyle(lineWidth:1.5,dash:[4,3]))
                    }
                    for n in ns {
                        let c = CGPoint(x:n.x*sz.width, y:n.y*sz.height)
                        ctx.fill(Path(ellipseIn:CGRect(x:c.x-18,y:c.y-18,width:36,height:36)),
                                 with:.color(n.ts.glowColor.opacity(0.18)))
                        ctx.stroke(Path(ellipseIn:CGRect(x:c.x-16,y:c.y-16,width:32,height:32)),
                                   with:.color(n.ts.glowColor.opacity(0.7)),lineWidth:1.5)
                        ctx.draw(Text(n.e).font(.system(size:14)),at:c)
                    }
                }
                .frame(height:180)
                .id(selected)
                .transition(.opacity)
            }
        }
    }
}
