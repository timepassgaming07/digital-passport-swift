import SwiftUI

struct HomeView: View {
    @State private var vm = HomeViewModel()
    @State private var floatY: CGFloat = 0
    @State private var appState = AppState.shared
    @Environment(\.colorScheme) private var scheme
    private var dark: Bool { appState.isDarkMode }

    var body: some View {
        ZStack {
            AmbientBackground(isDark:dark).ignoresSafeArea()
            ScrollView(showsIndicators:false) {
                VStack(spacing:20) {
                    HStack {
                        VStack(alignment:.leading,spacing:2) {
                            Text("Sovereign Trust").font(.largeTitle.bold())
                                .foregroundStyle(dark ? .white : Color(hex:"111827"))
                            Text("Identity Wallet").font(.subheadline)
                                .foregroundStyle(dark ? Color.white.opacity(0.65) : Color(hex:"374151"))
                        }
                        Spacer()
                        HStack(spacing:10) {
                            Circle().fill(Color(hex:"00FF88")).frame(width:8,height:8)
                                .shadow(color:Color(hex:"00FF88"),radius:5)
                            NavigationLink(value:NavRoute.settings) {
                                Image(systemName:"gearshape.fill").font(.body.weight(.semibold))
                                    .foregroundStyle(dark ? Color.white.opacity(0.75):Color(hex:"374151"))
                                    .frame(width:36,height:36)
                                    .glass(cornerRadius: .infinity)
                            }
                        }
                    }.padding(.top,16)

                    WalletSummaryCard(identity:vm.identity,floatY:floatY)

                    HStack(spacing:12) {
                        statTile("◈","\(vm.credentials.count)","Credentials")
                        statTile("🧾", "\(vm.recentVerifications.count)", "Recent Checks")
                        statTile("🕐",vm.recentVerifications.first.map{Formatters.timeAgo($0.verifiedAt)} ?? "–","Last Activity")
                    }
                    QuickActionsGrid(identity:vm.identity)
                    RecentVerificationsSection(results:vm.recentVerifications)
                }
                .padding(.horizontal,20)
                .padding(.top,8)
                .padding(.bottom,100)
            }
            .scrollContentBackground(.hidden)
        }
        .ignoresSafeArea(edges:.bottom)
        .task { await vm.load() }
        .onAppear { withAnimation(.stFloat) { floatY=3 } }
    }

    private func statTile(_ icon:String,_ value:String,_ label:String) -> some View {
        GlassCard(cornerRadius:20,innerPadding:14,style:.liquid) {
            VStack(alignment:.leading,spacing:4) {
                Text(icon).font(.title2)
                Text(value).font(.title2.bold()).foregroundStyle(Color.stCyan)
                Text(label).font(.caption.weight(.medium))
                    .foregroundStyle(dark ? Color.white.opacity(0.65):Color(hex:"374151"))
            }.frame(maxWidth:.infinity,alignment:.leading)
        }
    }
}
