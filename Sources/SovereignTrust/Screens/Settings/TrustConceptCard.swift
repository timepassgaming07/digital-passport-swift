import SwiftUI

struct TrustConceptCard: View {
    let number: Int
    let icon: String
    let title: String
    let description: String

    var body: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Label("\(number). \(title)", systemImage: icon)
                    .font(.stHeadline)
                    .foregroundStyle(Color.stCyan)
                Text(description)
                    .font(.stBody)
                    .foregroundStyle(Color.stSecondary)
            }
        }
    }
}
