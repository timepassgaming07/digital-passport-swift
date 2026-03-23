import SwiftUI
struct LoadingState: View {
    var message: String = "Loading…"
    var body: some View {
        VStack(spacing:16) {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.stCyan)).scaleEffect(1.3)
            Text(message).font(.stBodySm).foregroundStyle(Color.stSecondary)
        }
        .frame(maxWidth:.infinity, maxHeight:.infinity)
    }
}
