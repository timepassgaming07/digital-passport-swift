import SwiftUI
struct UseCaseGrid: View {
    private let cases:[( String,String,String)] = [
        ("🎓","Education","Tamper-proof degrees"),("🏭","Supply Chain","Product provenance"),
        ("🏥","Healthcare","Medical credentials"),("⚖️","Legal","Signed documents"),
        ("🗳️","Voting","Identity proofs"),("💼","Employment","Background checks"),
    ]
    var body: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading,spacing:12) {
                Label("4. Global Use Cases",systemImage:"globe.asia.australia.fill").font(.stHeadline).foregroundStyle(Color.stCyan)
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10) {
                    ForEach(cases,id:\.1) { (e,t,d) in
                        VStack(alignment:.leading,spacing:4) {
                            Text(e).font(.title2)
                            Text(t).font(.stHeadline).foregroundStyle(Color.stPrimary)
                            Text(d).font(.stCaption).foregroundStyle(Color.stSecondary)
                        }
                        .padding(12)
                        .glass(cornerRadius: 14)
                    }
                }
            }
        }
    }
}
