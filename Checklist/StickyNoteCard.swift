import SwiftUI
import Shimmer

struct StickyNoteCard: View {
    let index: Int
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var cardFrame: CGRect = .zero
    var onClick: (CGRect) -> Void
    
    var body: some View {
        VStack {
            Image(stickyNoteImageName(for: index))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 280)
                .clipped()
                .cornerRadius(16)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: isHovered ? 16 : 12,
                    x: 0,
                    y: isHovered ? 8 : 6
                )
                .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.03 : 1.0))
                .rotation3DEffect(
                    .degrees(rotationX),
                    axis: (x: 0.5, y: 0.0, z: 0.0)
                )
                .rotation3DEffect(
                    .degrees(rotationY),
                    axis: (x: 0.0, y: 0.5, z: 0.0)
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rotationX)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rotationY)
                .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3), value: isPressed)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                .overlay(
                    GeometryReader { geometry in
                        Color.clear
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let location):
                                    let width = geometry.size.width
                                    let height = geometry.size.height
                                    
                                    let percentageX = (location.x / width - 0.5) * 1
                                    let percentageY = (location.y / height - 0.5) * 1
                                    
                                    let maxRotation = 7.0
                                    rotationX = -percentageY * maxRotation
                                    rotationY = percentageX * maxRotation
                                    
                                    isHovered = true
                                    
                                case .ended:
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        rotationX = 0
                                        rotationY = 0
                                        isHovered = false
                                    }
                                }
                            }
                    }
                )
            
            Text("0\(index + 1). \(stickyNoteLabel(for: index))")
                .foregroundColor(.gray)
                .font(.system(size: 14))
                .padding(.top, 20)
                .shimmering(active: isHovered)
                .opacity(isHovered ? 1 : 1)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isHovered ? Color.hexColor("#f8f8f8") : Color.clear)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        )
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: CardFramePreferenceKey.self, value: geometry.frame(in: .global))
            }
        )
        .onPreferenceChange(CardFramePreferenceKey.self) { frame in
            cardFrame = frame
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                        isPressed = false
                    }
                    onClick(cardFrame)
                }
        )
    }
    
    private func stickyNoteImageName(for index: Int) -> String {
        switch index {
        case 0: return "Purple_home"
        case 1: return "Yellow_home"
        case 2: return "Green_home"
        default: return "Purple_home"
        }
    }
    
    private func stickyNoteLabel(for index: Int) -> String {
        switch index {
        case 0: return "Lavender"
        case 1: return "Banana"
        case 2: return "Kiwi"
        default: return "Unknown"
        }
    }
    
    private func getShimmerColor(for index: Int) -> String {
        switch index {
        case 0: return "#9F7AEA" // Lavender shimmer
        case 1: return "#F6E05E" // Banana shimmer
        case 2: return "#48BB78" // Kiwi shimmer
        default: return "#9F7AEA"
        }
    }
}

struct CardFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
