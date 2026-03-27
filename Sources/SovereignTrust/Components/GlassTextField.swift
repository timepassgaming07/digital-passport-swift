import SwiftUI

// MARK: - Glass Text Field
/// A text input styled with Apple's native material system + liquid glass enhancements.
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.stCyan)
            }
            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .glassInput()
    }
}

// MARK: - Glass Search Bar
/// A search-style input with glass styling.
struct GlassSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search…"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.5))
            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundStyle(.white)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassInput()
    }
}
