import SwiftUI
import AppKit

extension Color {
    // Unified color hex conversion methods
    static func hexColor(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return .black
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
    
    func hexString() -> String {
        let uiColor = NSColor(self)
        guard let components = uiColor.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let hex = String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        return hex
    }
    
    // ADD: Method to darken a color
    func darker(by amount: CGFloat = 0.1) -> Color {
        let nsColor = NSColor(self)
        guard let adjustedColor = nsColor.adjustBrightness(by: -amount) else {
            return self
        }
        return Color(adjustedColor)
    }
}

// Helper extension for NSColor
extension NSColor {
    func adjustBrightness(by amount: CGFloat) -> NSColor? {
        guard let color = usingColorSpace(.sRGB) else { return nil }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return NSColor(hue: h, saturation: s, brightness: max(0, min(1, b + amount)), alpha: a)
    }
}
