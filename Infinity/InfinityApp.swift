import SwiftUI

@main
struct InfinityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings window is opened from the popover gear button.
        // We only declare it here so macOS has a valid window to show.
        Settings {
            SettingsView()
        }
    }
}
