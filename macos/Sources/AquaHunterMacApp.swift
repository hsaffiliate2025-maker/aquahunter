import SwiftUI

@main
struct AquaHunterMacApp: App {
    var body: some Scene {
        WindowGroup {
            AquaShellView()
                .frame(minWidth: 980, minHeight: 680)
        }
        .defaultSize(width: 1180, height: 780)
    }
}
