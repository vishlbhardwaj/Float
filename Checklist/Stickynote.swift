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
        case .small: return (300, 370)
        case .medium: return (350, 420)
        case .large: return (400, 470)
        }
    }
}

class StickyNote: Identifiable, ObservableObject {
    let id = UUID()
    @Published var style: StickyNoteStyle
    @Published var items: [TodoItem]
    @Published var position: CGPoint
    @Published var listStyle: ListStyle
    @Published var fontStyle: FontStyle
    @Published var noteSize: StickyNoteSize
    @Published var fontSize: FontSize
    @Published var isShimmering: Bool = false
    
    init(style: StickyNoteStyle = .banana) {
        self.style = style
        self.items = []
        self.position = .zero
        self.listStyle = .bullet
        self.fontStyle = .simple
        self.noteSize = .medium
        self.fontSize = .medium
    }
    
    func updateNoteSize(to size: StickyNoteSize) {
        self.noteSize = size
    }
    
    func updateTextSize(to size: FontSize) {
        self.fontSize = size
    }
}
