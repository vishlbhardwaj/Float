import SwiftUI

struct EmojiFallingView: View {
    let emoji: String
    let triggerTime: Date
    let startPosition: CGPoint
    let index: Int
    
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 1.0
    
    // Starting position above the window with less horizontal spread
    private var startingPosition: CGPoint {
        CGPoint(
            x: CGFloat.random(in: 100...950),  // Reduced horizontal spread
            y: -50 - CGFloat.random(in: 0...150)
        )
    }
    
    private var fallDuration: Double {
        Double.random(in: 4.0...5.0)
    }
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 20))
            .position(startingPosition)
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .onAppear {
                // Set initial slight horizontal offset
                xOffset = CGFloat.random(in: -10...10)  // Reduced from -30...30
                
                let staggerDelay = Double(index) * 0.15
                
                // Start animation with minimal delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + staggerDelay) {
                    // Main falling motion - now with minimal horizontal movement
                    withAnimation(
                        .easeInOut(duration: fallDuration)
                    ) {
                        // Very subtle horizontal drift
                        xOffset += CGFloat.random(in: -5...5)  // Reduced horizontal drift
                        yOffset = 300
                    }
                    
                    // Fade out
                    withAnimation(
                        .easeIn(duration: fallDuration * 0.3)
                        .delay(fallDuration * 0.1)
                    ) {
                        opacity = 0
                    }
                }
            }
    }
}
