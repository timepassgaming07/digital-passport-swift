import SwiftUI

struct VerificationStepRow: View {
    let step: VerificationStep
    var isLast: Bool = false

    private var dotColor: Color {
        if step.isFailed   { return .stRed }
        if step.isComplete { return Color(hex:"00FF88") }
        if step.isActive   { return .stCyan }
        return .stQuaternary
    }

    var body: some View {
        HStack(alignment:.top, spacing:14) {
            VStack(spacing:0) {
                ZStack {
                    Circle().fill(dotColor.opacity(0.15)).frame(width:32,height:32)
                    if step.isActive && !step.isComplete && !step.isFailed {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.stCyan))
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: step.isFailed ? "xmark.circle.fill"
                              : step.isComplete ? "checkmark.circle.fill" : "circle")
                            .font(.system(size:18, weight:.semibold))
                            .foregroundStyle(dotColor)
                            .symbolEffect(.bounce, value:step.isComplete)
                    }
                }
                .shadow(color:dotColor.opacity(step.isActive || step.isComplete ? 0.6 : 0), radius:8)
                if !isLast {
                    Rectangle()
                        .fill(step.isComplete ? Color(hex:"00FF88").opacity(0.4) : Color.white.opacity(0.08))
                        .frame(width:2, height:24)
                        .animation(.stSpring.delay(0.15), value:step.isComplete)
                }
            }
            VStack(alignment:.leading, spacing:2) {
                Text(step.label)
                    .font(.stBodySm)
                    .foregroundStyle(step.isActive || step.isComplete ? Color.stPrimary : Color.stTertiary)
                if let detail = step.detail, step.isComplete || step.isFailed {
                    Text(detail)
                        .font(.stCaption)
                        .foregroundStyle(Color.stTertiary)
                        .transition(.opacity.combined(with:.offset(y:4)))
                }
            }
            .padding(.top,6)
            Spacer()
        }
        .animation(.stSpring, value:step.isComplete)
        .animation(.stSpring, value:step.isActive)
    }
}
