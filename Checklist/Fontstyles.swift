import SwiftUI
import AppKit

enum FontStyle: String, CaseIterable {
    case simple = "Regular"     // Renamed display name to "Regular"
    case monospaced = "Technical"  // Renamed display name to "Technical"
    case scribbled = "Scribbled"   // Kept as "Scribbled"
    
    var fontName: String {
        switch self {
        case .simple: return ".AppleSystemUIFont"
        case .monospaced: return "SFMono-Regular"  // SF Mono is Apple's monospaced font
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
            // Try several monospaced fonts that might be available on macOS
            if let font = NSFont(name: "SFMono-Regular", size: size) {
                return font
            } else if let font = NSFont(name: "Menlo-Regular", size: size) {
                return font
            } else if let font = NSFont(name: "Monaco", size: size) {
                return font
            } else if let font = NSFont(name: "Courier", size: size) {
                return font
            } else {
                return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
            }
            
        case .scribbled:
            // Try several handwriting fonts that might be available on macOS
            if let font = NSFont(name: "Bradley Hand", size: size) {
                return font
            } else if let font = NSFont(name: "Marker Felt", size: size) {
                return font
            } else if let font = NSFont(name: "Noteworthy", size: size) {
                return font
            } else if let font = NSFont(name: "Chalkboard", size: size) {
                return font
            } else if let font = NSFont(name: "Comic Sans MS", size: size) {
                return font
            } else {
                // Fall back to system font if none of the handwriting fonts are available
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
        return self.rawValue // This will return "14", "16", "18"
    }
}
