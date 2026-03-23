import SwiftUI
struct EmptyState: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        VStack(spacing:16) {
            Image(systemName:icon).font(.system(size:48)).foregroundStyle(Color.stTertiary)
            Text(title).font(.stHeadline).foregroundStyle(Color.stSecondary)
            Text(message).font(.stBodySm).foregroundStyle(Color.stTertiary).multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth:.infinity)
    }
}
