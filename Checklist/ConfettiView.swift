import SwiftUI

struct ConfettiView: View {
    @Binding var isVisible: Bool
    let duration: Double = 2.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<50) { i in
                    Circle()
                        .fill(Color(hue: Double.random(in: 0...1),
                                  saturation: 0.8,
                                  brightness: 0.8))
                        .frame(width: 8, height: 8)
                        .position(x: .random(in: 0...geometry.size.width),
                                y: isVisible ?
                                    .random(in: geometry.size.height...geometry.size.height + 100) :
                                    -20)
                        .animation(
                            Animation.interpolatingSpring(stiffness: 50, damping: 3)
                                .speed(0.7)
                                .delay(Double.random(in: 0...0.5))
                                .repeatCount(1, autoreverses: false),
                            value: isVisible
                        )
                }
            }
        }
        .onAppear {
            isVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isVisible = false
            }
        }
    }
}
