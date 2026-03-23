import SwiftUI
struct CredentialFilterBar: View {
    @Binding var active: CredentialFilter
    let onSelect: (CredentialFilter) -> Void
    var body: some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:8) {
                ForEach(CredentialFilter.allCases,id:\.self) { f in
                    Button { active = f; onSelect(f) } label: {
                        Text(f.rawValue).font(.stCaption)
                            .foregroundStyle(active==f ? Color.stCyan : Color.stSecondary)
                            .padding(.horizontal,12).padding(.vertical,7)
                            .background(active==f ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.clear),in:Capsule())
                            .overlay(Capsule().stroke(active==f ? Color.stCyan.opacity(0.4) : Color.white.opacity(0.1),lineWidth:1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}
