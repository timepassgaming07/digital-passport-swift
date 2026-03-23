import SwiftUI
struct VerificationFlowCard: View {
    let activeStep:Int
    private let labels = ["QR Decode","Payload Parse","Signature Check","Issuer Registry","Trust Graph"]
    var body: some View {
        GlassCard(cornerRadius:24) {
            VStack(alignment:.leading,spacing:14) {
                Label("3. Verification Engine",systemImage:"gearshape.2.fill").font(.stHeadline).foregroundStyle(Color.stCyan)
                ForEach(Array(labels.enumerated()),id:\.offset) { i,l in
                    VerificationStepRow(
                        step:VerificationStep(number:i+1, label:l,
                            isActive:activeStep==i, isComplete:activeStep>i),
                        isLast:i==labels.count-1)
                }
            }
        }
    }
}
