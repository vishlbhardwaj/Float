import SwiftUI
import Shimmer

enum StickyNoteStyle: String, CaseIterable {
    case lavender // Changed from brown
    case banana   // Changed from yellow
    case kiwi     // Changed from blue
    
    var backgroundColor: Color {
        switch self {
        case .lavender:
            return Color(red: 0xE5 / 255.0, green: 0xD7 / 255.0, blue: 0xEE / 255.0) // Purple (#E5D7EE)
        case .banana:
            return Color(red: 0xFF / 255.0, green: 0xEB / 255.0, blue: 0xBE / 255.0) // Yellow (#FFEBBE)
        case .kiwi:
            return Color(red: 0xCF / 255.0, green: 0xE8 / 255.0, blue: 0xBE / 255.0) // Green (#CFE8BE)
        }
    }
}

enum ListStyle {
    case checkbox
    case bullet
}

class StickyNote: Identifiable, ObservableObject {
    let id = UUID()
    var style: StickyNoteStyle
    @Published var items: [TodoItem]
    @Published var position: CGPoint
    @Published var listStyle: ListStyle = .checkbox
    @Published var isShimmering = false
    @Published var fontStyle: FontStyle = .simple  // Add this property
    
    init(style: StickyNoteStyle) {
        self.style = style
        self.items = []
        self.position = CGPoint(x: 0, y: 0)
    }
    
    func updateTextSize(to newSize: FontSize) {
        isShimmering = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                for index in self.items.indices {
                    self.items[index].fontSize = newSize
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isShimmering = false
            }
        }
    }
    
    func updateTextSizeSmoothly(to newSize: FontSize) {
        isShimmering = true
        
        // First update the model without animation
        for index in self.items.indices {
            self.items[index].fontSize = newSize
        }
        
        // Then trigger a smooth visual update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.objectWillChange.send()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isShimmering = false
            }
        }
    }
}
