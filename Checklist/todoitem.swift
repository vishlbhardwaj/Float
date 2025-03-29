import Foundation
import SwiftUI

class TodoItem: ObservableObject, Identifiable {
    let id = UUID()
    weak var parentNote: StickyNote?
    
    @Published var text: String
    @Published var isCompleted: Bool
    @Published var textColor: Color
    @Published var fontSize: FontSize
    @Published var fontStyle: FontStyle
    
    init(text: String = "", isCompleted: Bool = false) {
        self.text = text
        self.isCompleted = isCompleted
        self.textColor = .primary
        self.fontSize = .medium
        self.fontStyle = .simple
    }
}
