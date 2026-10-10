import SwiftUI

/// Host for the showcase screens. Open one directly at launch:
/// `xcrun simctl launch <udid> dev.heyparsa.liquidglassshowcase -screen 3`
/// (UserDefaults reads `-key value` launch arguments.) Without an argument the app shows a
/// list of the screens.
@main
struct ShowcaseApp: App {
    var body: some Scene {
        WindowGroup {
            if let screen = ScreenID.launch(UserDefaults.standard.integer(forKey: "screen")) {
                screen.view
            } else {
                Launcher()
            }
        }
    }
}
