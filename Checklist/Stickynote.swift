import SwiftUI
import Shimmer

enum StickyNoteStyle: String, CaseIterable {
    case lavender
    case banana
    case kiwi
    
    var backgroundColor: Color {
        switch self {
        case .lavender:
            return Color(red: 0xE5 / 255.0, green: 0xD7 / 255.0, blue: 0xEE / 255.0)
        case .banana:
            return Color(red: 0xFF / 255.0, green: 0xEB / 255.0, blue: 0xBE / 255.0)
        case .kiwi:
            return Color(red: 0xCF / 255.0, green: 0xE8 / 255.0, blue: 0xBE / 255.0)
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
        case .small: return (300, 370)
        case .medium: return (350, 420)
        case .large: return (400, 470)
        }
    }
}

class StickyNote: ObservableObject, Identifiable {
    let id = UUID()
    let style: StickyNoteStyle
    
    @Published var items: [TodoItem]
    @Published var position: CGPoint
    @Published var listStyle: ListStyle
    @Published var isShimmering: Bool
    @Published var fontStyle: FontStyle
    @Published var noteSize: StickyNoteSize
    @Published var fontSize: FontSize
    
    init(style: StickyNoteStyle) {
        self.style = style
        self.position = CGPoint(x: 0, y: 0)
        self.listStyle = .checkbox
        self.isShimmering = false
        self.fontStyle = .simple
        self.noteSize = .medium
        self.fontSize = .medium
        self.items = []
        
        // Initialize with one empty TodoItem
        let initialItem = TodoItem()
        initialItem.parentNote = self
        self.items = [initialItem]
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
    
    func addNewItem() {
        let newItem = TodoItem()
        newItem.parentNote = self
        items.append(newItem)
    }
}
