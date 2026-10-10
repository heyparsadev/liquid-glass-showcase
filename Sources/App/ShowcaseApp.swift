import SwiftUI

/// Host for the six showcase screens. Open one directly at launch:
/// `xcrun simctl launch <udid> dev.heyparsa.liquidglassshowcase -screen 3`
/// (UserDefaults reads `-key value` launch arguments.)
@main
struct ShowcaseApp: App {
    var body: some Scene {
        WindowGroup {
            ScreenID(launchValue: UserDefaults.standard.integer(forKey: "screen")).view
        }
    }
}
