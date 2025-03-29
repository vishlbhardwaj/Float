import SwiftUI
import Shimmer
import SpriteKit

struct ContentView: View {
    @State private var stickyNotes: [StickyNote] = []
    @State private var selectedStickyNote: StickyNoteStyle? = nil
    @State private var particleTrigger: Date = Date()
    @State private var lastClickedPosition: CGPoint = .zero
    
    private let cardWidth: CGFloat = 280
    private let cardSpacing: CGFloat = 8
    private let windowWidth: CGFloat = 1050
    private let sidePadding: CGFloat = 125
    
    var body: some View {
        let totalCardsWidth = (cardWidth * 3) + (cardSpacing * 2)
        
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 40) {
                        // Header section
                        VStack(alignment: .leading, spacing: 16) {
                            // Logo
                            Image("Float_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 32)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            
                            // Title and Date row
                            HStack(alignment: .bottom, spacing: 20) {
                                Text("Select a sticky note to get started")
                                    .font(.system(size: 26, weight: .semibold))
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.black)
                                    .lineLimit(nil)
                                
                                Spacer()
                                
                                Text(getCurrentDate())
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, sidePadding)
                        
                        // HStack of Sticky Note Cards
                        HStack(spacing: cardSpacing) {
                            ForEach(0..<3) { index in
                                StickyNoteCard(index: index) { frame in
                                    let newNote = StickyNote(style: StickyNoteStyle.allCases[index])
                                    selectedStickyNote = nil  // Reset the selection
                                    lastClickedPosition = CGPoint(x: frame.midX, y: frame.minY)
                                    particleTrigger = Date() // Update trigger time
                                    DispatchQueue.main.async {
                                        selectedStickyNote = newNote.style // Set new selection
                                    }
                                    openStickyNoteWindow(newNote: newNote)
                                }
                                .frame(width: cardWidth, height: 400)
                            }
                        }
                        .frame(width: totalCardsWidth)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 24)
                }
                
                Spacer(minLength: 100)
                
                // Footer
                HStack {
                    Text("Stick it, strike it, and smile when you do it")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray.opacity(0.5))
                    Spacer()
                }
                .padding(.horizontal, sidePadding)
            }
            .padding(.vertical, 60)
            
            // Emoji Falling Effect
            if let selectedStickyNote = selectedStickyNote {
                ForEach(0..<12) { index in
                    EmojiFallingView(
                        emoji: emojiForStickyNote(selectedStickyNote),
                        triggerTime: particleTrigger,
                        startPosition: lastClickedPosition,
                        index: index
                    )
                }
            }
        }
        .frame(width: windowWidth, height: 750)
    }
    
    private func getCurrentDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, d MMM"
        return dateFormatter.string(from: Date())
    }
    
    private func openStickyNoteWindow(newNote: StickyNote) {
        let panel = FloatingPanel(
            contentRect: NSRect(x: 20, y: 20, width: 350, height: 420),
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties
        panel.minSize = NSSize(width: 350, height: 420)
        panel.maxSize = NSSize(width: 350, height: 420)
        
        let hostingView = NSHostingView(rootView:
                                        StickyNoteView(note: newNote) {
            withAnimation(.easeInOut(duration: 0.3)) {
                if let index = stickyNotes.firstIndex(where: { $0.id == newNote.id }) {
                    stickyNotes.remove(at: index)
                }
            }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().alphaValue = 0.0
            }) {
                panel.close()
            }
        }
        )
        
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        
        // Position panel randomly within screen bounds
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let padding: CGFloat = 100
            let randomX = CGFloat.random(in: padding...(screenFrame.width - panel.frame.width - padding))
            let randomY = CGFloat.random(in: padding...(screenFrame.height - panel.frame.height - padding))
            panel.setFrameOrigin(NSPoint(x: randomX, y: randomY))
        }
        
        // Animate panel appearance
        panel.alphaValue = 0.0
        panel.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 1.0
        }) {
            panel.makeFirstResponder(hostingView)
        }
        
        stickyNotes.append(newNote)
    }
    
    private func emojiForStickyNote(_ style: StickyNoteStyle) -> String {
        switch style {
        case .lavender:
            return "🌸"
        case .banana:
            return "🍌"
        case .kiwi:
            return "💚"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
