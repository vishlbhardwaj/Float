import Foundation
import SwiftUI

struct TodoItem: Identifiable {
    let id = UUID()
    var text: String
    var isCompleted: Bool
    var textColor: Color = .black
    var fontSize: FontSize = .medium
    var fontStyle: FontStyle = .simple  // Make sure this matches the enum case
    let createdAt = Date()
    
    init(text: String, isCompleted: Bool, textColor: Color = .black, fontSize: FontSize = .medium, fontStyle: FontStyle? = nil) {
        self.text = text
        self.isCompleted = isCompleted
        self.textColor = textColor
        self.fontSize = fontSize
        self.fontStyle = fontStyle ?? .simple  // Make sure this matches the enum case
    }
}
