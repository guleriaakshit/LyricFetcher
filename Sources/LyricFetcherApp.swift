import SwiftUI
import AppKit

@main
struct LyricFetcherApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Force dark appearance for the premium look
                    if let darkAppearance = NSAppearance(named: .darkAqua) {
                        NSApp?.appearance = darkAppearance
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .defaultSize(width: 720, height: 620)
    }
}
