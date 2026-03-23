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
    var material: AnyShapeStyle {
        self == .primary ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.ultraThinMaterial)
    }
    var borderColor: Color {
        switch self {
        case .primary:   return Color(hex:"22D3EE").opacity(0.55)
        case .secondary: return Color.white.opacity(0.20)
        case .danger:    return Color(hex:"FF3355").opacity(0.55)
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
}

struct GlassButton: View {
    let label: String; let icon: String
    var variant: GlassButtonVariant = .primary
    var isLoading: Bool = false
    var fullWidth: Bool = false
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action:action) {
            HStack(spacing:8) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint:variant.textColor)).scaleEffect(0.8)
                } else {
                    Image(systemName:icon).font(.system(.body,weight:.semibold))
                }
                Text(label).font(.system(.body,design:.rounded,weight:.semibold))
                if fullWidth { Spacer() }
            }
            .foregroundStyle(variant.textColor)
            .padding(.horizontal,fullWidth ? 20:22).padding(.vertical,13)
            .frame(maxWidth:fullWidth ? .infinity:nil)
            .background(variant.material,in:Capsule())
            .overlay(Capsule().fill(LinearGradient(colors:[Color.white.opacity(0.20),.clear],startPoint:.topLeading,endPoint:.bottomTrailing)).allowsHitTesting(false))
            .overlay(Capsule().stroke(variant.borderColor,lineWidth:0.8))
            .shadow(color:variant.glowColor.opacity(0.40),radius:14)
            .shadow(color:.black.opacity(0.18),radius:5,x:0,y:3)
            .scaleEffect(pressed ? 0.96:1.0).brightness(pressed ? 0.06:0)
            .animation(.spring(response:0.25,dampingFraction:0.70),value:pressed)
        }
        .disabled(isLoading)
        .simultaneousGesture(DragGesture(minimumDistance:0).onChanged{_ in pressed=true}.onEnded{_ in pressed=false})
    }
}
