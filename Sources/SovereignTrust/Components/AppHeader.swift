import SwiftUI

struct AppHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment:.center) {
            VStack(alignment:.leading, spacing:2) {
                Text(title).font(.stTitle1).foregroundStyle(Color.stPrimary)
                if let sub = subtitle {
                    Text(sub).font(.stBodySm).foregroundStyle(Color.stSecondary)
                }
            }
            Spacer()
            trailing
        }
        .padding(.top, 8)
    }
}
