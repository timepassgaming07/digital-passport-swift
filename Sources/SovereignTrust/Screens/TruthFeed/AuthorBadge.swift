import SwiftUI

struct AuthorBadge: View {
    let author: PostAuthor
    var showDid: Bool = false

    var body: some View {
        HStack(spacing:10) {
            ZStack {
                Circle().stroke(author.trustState.glowColor.opacity(0.5),lineWidth:1.5).frame(width:40,height:40)
                Text(author.avatarEmoji).font(.title3)
                if author.isVerified {
                    Image(systemName:"checkmark.seal.fill").font(.system(size:11))
                        .foregroundStyle(Color.stCyan).offset(x:13,y:13)
                }
            }
            VStack(alignment:.leading,spacing:2) {
                Text(author.displayName).font(.stHeadline).foregroundStyle(Color.stPrimary)
                if showDid {
                    Text(Formatters.shortDID(author.did)).font(.stMonoSm).foregroundStyle(Color.stTertiary)
                } else {
                    Text(author.handle).font(.stCaption).foregroundStyle(Color.stSecondary)
                }
                if let inst = author.institution {
                    Text(inst).font(.stCaption).foregroundStyle(Color.stTertiary)
                }
            }
            Spacer()
            TrustBadge(state:author.trustState,size:.small)
        }
    }
}
