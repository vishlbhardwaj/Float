import AppKit
import SwiftUI

class FloatingPanel: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        let expandedRect = NSRect(
            x: contentRect.origin.x,
            y: contentRect.origin.y,
            width: 500,
            height: 570
        )
        
        super.init(contentRect: expandedRect,
                  styleMask: [.titled, .fullSizeContentView],
                  backing: backing,
                  defer: flag)
        
        self.isFloatingPanel = true
        
        // Set to normal window level for full interactivity
        self.level = NSWindow.Level.normal
        
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.isMovableByWindowBackground = true
        
        // Basic collection behavior for normal window functionality
        self.collectionBehavior = [.canJoinAllSpaces]
        
        // Ensure window stays interactive
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        
        // Remove window buttons
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        if let contentView = self.contentView {
            contentView.wantsLayer = true
            contentView.layer?.masksToBounds = false
            contentView.layer?.cornerRadius = 20
        }
        
        // Add observer for full screen windows
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidEnterFullScreen),
            name: NSWindow.didEnterFullScreenNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillExitFullScreen),
            name: NSWindow.willExitFullScreenNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func windowDidEnterFullScreen(_ notification: Notification) {
        if let fullScreenWindow = notification.object as? NSWindow, fullScreenWindow != self {
            // Hide when another window goes full screen
            self.orderOut(nil)
        }
    }
    
    @objc private func windowWillExitFullScreen(_ notification: Notification) {
        if let fullScreenWindow = notification.object as? NSWindow, fullScreenWindow != self {
            // Show when full screen window exits
            self.orderFront(nil)
        }
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    // Ensure proper window ordering and interaction
    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        
        // Check if any window is in full screen
        if let fullScreenWindow = NSApp.windows.first(where: { $0.styleMask.contains(.fullScreen) }) {
            self.orderOut(nil)
        }
    }
}
