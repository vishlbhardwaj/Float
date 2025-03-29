import SwiftUI
import AppKit

struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var textColor: Color
    var fontSize: FontSize
    var fontStyle: FontStyle
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, text, isCompleted, textColor, fontSize, fontStyle, createdAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(textColor.hexString(), forKey: .textColor)
        try container.encode(fontSize.rawValue, forKey: .fontSize)
        try container.encode(fontStyle.rawValue, forKey: .fontStyle)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        let hexColor = try container.decode(String.self, forKey: .textColor)
        textColor = Color.hexColor(hexColor)
        let fontSizeRaw = try container.decode(String.self, forKey: .fontSize)
        fontSize = FontSize(rawValue: fontSizeRaw) ?? .medium
        let fontStyleRaw = try container.decode(String.self, forKey: .fontStyle)
        fontStyle = FontStyle(rawValue: fontStyleRaw) ?? .simple
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    init(id: UUID = UUID(), text: String, isCompleted: Bool, textColor: Color, fontSize: FontSize, fontStyle: FontStyle, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.textColor = textColor
        self.fontSize = fontSize
        self.fontStyle = fontStyle
        self.createdAt = createdAt
    }
    
    static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.text == rhs.text &&
               lhs.isCompleted == rhs.isCompleted &&
               lhs.textColor.hexString() == rhs.textColor.hexString() &&
               lhs.fontSize == rhs.fontSize &&
               lhs.fontStyle == rhs.fontStyle &&
               lhs.createdAt == rhs.createdAt
    }
}
