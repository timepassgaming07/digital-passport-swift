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
                        .background(vm.filter==f ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.clear),in:Capsule())
                        .overlay(Capsule().stroke(vm.filter==f ? Color.stCyan.opacity(0.5) : Color.white.opacity(0.1),lineWidth:1))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal,16).padding(.vertical,8)
        }
    }
}
