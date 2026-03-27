import UIKit

func setupGlobalAppearance() {
    // Navigation bar — let iOS 26 liquid glass handle backgrounds
    let nav = UINavigationBarAppearance()
    nav.configureWithDefaultBackground()
    nav.backgroundColor = UIColor.clear
    nav.shadowColor = .clear
    nav.titleTextAttributes      = [.foregroundColor: UIColor.white]
    nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    UINavigationBar.appearance().standardAppearance   = nav
    UINavigationBar.appearance().scrollEdgeAppearance = nav
    UINavigationBar.appearance().compactAppearance    = nav
    UINavigationBar.appearance().tintColor = UIColor(red:0.13, green:0.83, blue:0.93, alpha:1)

    // Tab bar — let iOS 26 liquid glass handle backgrounds
    let tab = UITabBarAppearance()
    tab.configureWithDefaultBackground()
    tab.backgroundColor = UIColor.clear
    tab.shadowColor = .clear
    UITabBar.appearance().standardAppearance = tab
    UITabBar.appearance().scrollEdgeAppearance = tab
}
