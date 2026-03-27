import SwiftUI
struct FeedFilterBar: View {
    @Bindable var vm: TruthFeedViewModel
    var body: some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:8) {
                ForEach(FeedFilter.allCases,id:\.self) { f in
                    Button { vm.applyFilter(f) } label: {
                        HStack(spacing:5) {
                            Text(f.rawValue).font(.stCaption)
                                .foregroundStyle(vm.filter==f ? Color.stCyan : Color.stSecondary)
                            let n = vm.count(f)
                            if n > 0 {
                                Text("\(n)").font(.stLabel)
                                    .foregroundStyle(vm.filter==f ? Color.stCyan : Color.stTertiary)
                                    .padding(.horizontal,5).padding(.vertical,2)
                                    .background(vm.filter==f ? Color.stCyan.opacity(0.15) : .clear,in:Capsule())
                            }
                        }
                        .padding(.horizontal,14).padding(.vertical,8)
                        .glassButton(glow: vm.filter==f ? Color.stCyan : .clear, glowIntensity: vm.filter==f ? 0.30 : 0)
                        .overlay(Capsule().stroke(vm.filter==f ? Color.stCyan.opacity(0.50) : Color.white.opacity(0.12),lineWidth:1))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal,16).padding(.vertical,8)
        }
    }
}
