import SwiftUI
import AppKit

enum FontStyle: String, CaseIterable {
    case simple = "Regular"     // Regular system font
    case monospaced = "Technical"  // Monospaced font
    case scribbled = "Scribbled"   // Handwritten style
    
    var fontName: String {
        switch self {
        case .simple: return ".AppleSystemUIFont"
        case .monospaced: return "SFMono-Regular"
        case .scribbled: return "Bradley Hand"
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
    
    func font(size: CGFloat) -> NSFont {
        switch self {
        case .simple:
            return NSFont.systemFont(ofSize: size)
            
        case .monospaced:
            if let font = NSFont(name: "SFMono-Regular", size: size) {
                return font
            } else if let font = NSFont(name: "Menlo-Regular", size: size) {
                return font
            } else {
                return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
            }
            
        case .scribbled:
            if let font = NSFont(name: "Bradley Hand", size: size) {
                return font
            } else if let font = NSFont(name: "Noteworthy", size: size) {
                return font
            } else {
                return NSFont.systemFont(ofSize: size)
            }
        }
    }
}

enum FontSize: String, CaseIterable {
    case small = "14"
    case medium = "16"
    case large = "18"
    
    var size: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
    
    var name: String {
        return self.rawValue
    }
}
