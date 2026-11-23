import SwiftUI

@main
struct KaartenSlokkenApp: App {
    var body: some Scene {
        WindowGroup {
            WebView()
                .ignoresSafeArea()
                .background(Color(red: 0.122, green: 0.302, blue: 0.227))
        }
    }
}
