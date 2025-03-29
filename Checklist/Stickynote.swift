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

enum StickyNoteSize: String, CaseIterable {
    case small
    case medium
    case large
    
    var dimensions: (width: CGFloat, height: CGFloat) {
        switch self {
        case .small: return (320, 400)
        case .medium: return (380, 450)
        case .large: return (440, 480) 
        }
    }
}

class StickyNote: Identifiable, ObservableObject {
    let id = UUID()
    var style: StickyNoteStyle
    @Published var items: [TodoItem]
    @Published var position: CGPoint
    @Published var listStyle: ListStyle = .checkbox
    @Published var isShimmering = false
    @Published var fontStyle: FontStyle = .simple
    @Published var noteSize: StickyNoteSize = .medium
    @Published var fontSize: FontSize = .medium
    
    init(style: StickyNoteStyle) {
        self.style = style
        self.items = []
        self.position = CGPoint(x: 0, y: 0)
    }
    
    func updateNoteSize(to newSize: StickyNoteSize) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.6)) {
            noteSize = newSize
        }
    }
    
    func updateTextSize(to newSize: FontSize) {
        isShimmering = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            fontSize = newSize
            for index in items.indices {
                items[index].fontSize = newSize
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.isShimmering = false
            }
        }
    }
}
