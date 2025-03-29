import SwiftUI
import Sparkle

@main
struct ChecklistApp: App {
    
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        // Set up window properties asynchronously
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                // Disable window resizing
                window.styleMask.remove(.resizable)
                
                // Set fixed size
                window.setContentSize(NSSize(width: 1000, height: 800))
                window.maxSize = NSSize(width: 1000, height: 800)
                window.minSize = NSSize(width: 1000, height: 800)
                
                // Center window
                window.center()
                
                // Set background color
                window.backgroundColor = .white
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
