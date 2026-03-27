import SwiftUI

struct SettingsView: View {
    let identity: Identity
    @State private var appState = AppState.shared
    @State private var biometricResult: BiometricTestResult?
    @State private var showBioSheet = false
    @State private var keyFP = "SE-…"
    @Environment(\.colorScheme) private var scheme
    private var dark: Bool { appState.isDarkMode }
    private var textColor: Color { dark ? .white : Color(hex:"111827") }
    private var subColor: Color { dark ? Color.white.opacity(0.65) : Color(hex:"374151") }

    var body: some View {
        ScreenContainer {
            VStack(spacing:18) {
                // Profile card — FROST
                GlassCard(cornerRadius:26,innerPadding:16,style:.liquid) {
                    HStack(spacing:14) {
                        ZStack {
                            Circle().stroke(identity.trustState.glowColor.opacity(0.5),lineWidth:2).frame(width:62,height:62)
                            Text(identity.avatarEmoji).font(.system(size:30))
                        }
                        VStack(alignment:.leading,spacing:3) {
                            Text(identity.displayName).font(.title3.weight(.semibold)).foregroundStyle(textColor)
                            Text(identity.handle).font(.caption).foregroundStyle(subColor)
                            Text(Formatters.shortDID(identity.did)).font(.system(.caption2,design:.monospaced)).foregroundStyle(subColor.opacity(0.6))
                        }
                        Spacer()
                    }
                }

                // THEME TOGGLE — Apple native toggle with liquid glass
                GlassCard(cornerRadius:22,innerPadding:16,style:.liquid) {
                    Toggle(isOn: Bindable(appState).isDarkMode) {
                        HStack(spacing:12) {
                            Image(systemName:dark ? "moon.fill" : "sun.max.fill")
                                .foregroundStyle(dark ? Color.stPurple : Color(hex:"F59E0B"))
                                .font(.title3)
                                .shadow(color:dark ? Color.stPurple.opacity(0.5) : Color(hex:"F59E0B").opacity(0.5),radius:6)
                                .contentTransition(.symbolEffect(.replace))
                            VStack(alignment:.leading,spacing:2) {
                                Text(dark ? "Dark Mode" : "Light Mode")
                                    .font(.system(.headline, design:.rounded, weight:.semibold))
                                    .foregroundStyle(textColor)
                                Text(dark ? "Tap to switch to light" : "Tap to switch to dark")
                                    .font(.system(.caption, design:.rounded))
                                    .foregroundStyle(subColor)
                            }
                        }
                    }
                    .tint(Color.stPurple)
                }

                // Security — LIQUID
                GlassCard(cornerRadius:22,innerPadding:16,style:.liquid) {
                    VStack(alignment:.leading,spacing:0) {
                        Text("Security").font(.caption.weight(.medium)).foregroundStyle(subColor.opacity(0.7)).padding(.bottom,12)
                        row("faceid",identity.biometryType.rawValue,"Active",.stCyan)
                        Divider().background(Color.white.opacity(0.08)).padding(.vertical,10)
                        row("key.fill","Hardware Key",keyFP,.stPurple)
                        Divider().background(Color.white.opacity(0.08)).padding(.vertical,10)
                        HStack {
                            Image(systemName:"bolt.fill").foregroundStyle(Color.stCyan).frame(width:24)
                            Text("Run Biometric Test").foregroundStyle(textColor)
                            Spacer()
                            GlassButton(label:"Test",icon:"faceid",variant:.primary) { Task { await runTest() } }
                        }
                    }
                }

                // Trust Engine
                NavigationLink(value:NavRoute.trustEngine) {
                    GlassCard(cornerRadius:22,innerPadding:16,style:.liquid) {
                        HStack {
                            Image(systemName:"network").foregroundStyle(Color.stCyan).font(.title2)
                                .shadow(color: Color.stCyan.opacity(0.4),radius:6)
                            VStack(alignment:.leading,spacing:2) {
                                Text("Trust Engine").font(.headline.weight(.semibold)).foregroundStyle(textColor)
                                Text("Explore the trust graph").font(.caption).foregroundStyle(subColor)
                            }
                            Spacer()
                            Image(systemName:"chevron.right").foregroundStyle(subColor.opacity(0.6))
                        }
                    }
                }.buttonStyle(.plain)

                // Glass Demo
                NavigationLink(value:NavRoute.glassDemo) {
                    GlassCard(cornerRadius:22,innerPadding:16,style:.liquid) {
                        HStack {
                            Image(systemName:"sparkles").foregroundStyle(Color.stPurple).font(.title2)
                                .shadow(color: Color.stPurple.opacity(0.4),radius:6)
                            VStack(alignment:.leading,spacing:2) {
                                Text("Glass Demo").font(.headline.weight(.semibold)).foregroundStyle(textColor)
                                Text("Liquid glass component gallery").font(.caption).foregroundStyle(subColor)
                            }
                            Spacer()
                            Image(systemName:"chevron.right").foregroundStyle(subColor.opacity(0.6))
                        }
                    }
                }.buttonStyle(.plain)

                // About
                GlassCard(cornerRadius:22,innerPadding:16,style:.liquid) {
                    VStack(alignment:.leading,spacing:0) {
                        Text("About").font(.caption.weight(.medium)).foregroundStyle(subColor.opacity(0.7)).padding(.bottom,12)
                        row("info.circle","Version",AppConstants.appVersion)
                        Divider().background(Color.white.opacity(0.08)).padding(.vertical,10)
                        row("hammer.fill","Build",AppConstants.buildNumber)
                        Divider().background(Color.white.opacity(0.08)).padding(.vertical,10)
                        row("iphone","Platform","iOS 17+")
                    }
                }
            }
        }
        .navigationTitle("Settings")

        .toolbarColorScheme(dark ? .dark:.light,for:.navigationBar)
        .sheet(isPresented:$showBioSheet) { bioSheet }
        .task { await loadFP() }
    }

    private func row(_ icon:String,_ label:String,_ value:String,_ color:Color = .stSecondary) -> some View {
        HStack {
            Image(systemName:icon).foregroundStyle(color).frame(width:24)
            Text(label).foregroundStyle(textColor)
            Spacer()
            Text(value).font(.caption).foregroundStyle(subColor).lineLimit(1)
        }
    }
    private var bioSheet: some View {
        ZStack {
            AmbientBackground(isDark:dark).ignoresSafeArea()
            VStack(spacing:24) {
                Spacer()
                if let r = biometricResult {
                    Image(systemName:r.success ? "checkmark.circle.fill":"xmark.circle.fill")
                        .font(.system(size:64)).foregroundStyle(r.success ? Color(hex:"00FF88"): Color.stRed)
                    Text(r.success ? "Biometrics Working":"Biometrics Failed").font(.title2.bold()).foregroundStyle(textColor)
                    if let e = r.errorMessage { Text(e).font(.subheadline).foregroundStyle(subColor) }
                }
                Spacer()
                GlassButton(label:"Done",icon:"checkmark",fullWidth:true) { showBioSheet=false }
                    .padding(.horizontal,32).padding(.bottom,40)
            }
        }
    }
    private func runTest() async {
        let r = await BiometricTestService.shared.runTest()
        await MainActor.run { biometricResult=r; showBioSheet=true }
    }
    private func loadFP() async {
        let fp = (try? await SecureEnclaveService.shared.fingerprint()) ?? "SE-[unavailable]"
        await MainActor.run { keyFP=fp }
    }
}
