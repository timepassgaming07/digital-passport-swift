import UIKit

func setupGlobalAppearance() {
    let nav = UINavigationBarAppearance()
    nav.configureWithTransparentBackground()
    nav.titleTextAttributes      = [.foregroundColor: UIColor.white]
    nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    UINavigationBar.appearance().standardAppearance   = nav
    UINavigationBar.appearance().scrollEdgeAppearance = nav
    UINavigationBar.appearance().compactAppearance    = nav
    UINavigationBar.appearance().tintColor = UIColor(red:0.13,green:0.83,blue:0.93,alpha:1)
    let tab = UITabBarAppearance()
    tab.configureWithTransparentBackground()
    UITabBar.appearance().standardAppearance = tab
    UITabBar.appearance().scrollEdgeAppearance = tab
}
