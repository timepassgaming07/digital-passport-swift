import SwiftUI

enum GlassButtonVariant {
    case primary, secondary, danger, ghost
    var textColor: Color {
        switch self {
        case .primary:   return Color(hex:"22D3EE")
        case .secondary: return .white
        case .danger:    return Color(hex:"FF3355")
        case .ghost:     return Color.white.opacity(0.7)
        }
    }
    var borderColor: Color {
        switch self {
        case .primary:   return Color(hex:"22D3EE").opacity(0.4)
        case .secondary: return Color.white.opacity(0.2)
        case .danger:    return Color(hex:"FF3355").opacity(0.4)
        case .ghost:     return Color.white.opacity(0.12)
        }
    }
    var glowColor: Color {
        switch self {
        case .primary: return Color(hex:"22D3EE")
        case .danger:  return Color(hex:"FF3355")
        default:       return .clear
        }
    }
    var glowIntensity: Double {
        switch self {
        case .primary: return 0.35
        case .danger:  return 0.35
        default:       return 0
        }
    }
}

struct GlassButton: View {
    let label: String; let icon: String
    var variant: GlassButtonVariant = .primary
    var isLoading: Bool = false
    var fullWidth: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: variant.textColor)).scaleEffect(0.8)
                } else {
                    Image(systemName: icon).font(.system(.body, weight: .semibold))
                }
                Text(label).font(.system(.body, design: .rounded, weight: .semibold))
                if fullWidth { Spacer() }
            }
            .foregroundStyle(variant.textColor)
            .padding(.horizontal, fullWidth ? 20 : 22).padding(.vertical, 13)
            .frame(maxWidth: fullWidth ? .infinity : nil)
        }
        .buttonStyle(.glass)
        .disabled(isLoading)
    }
}
