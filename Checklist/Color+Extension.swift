import SwiftUI

extension Color {
    func darker(by amount: CGFloat = 0.1) -> Color {
        let uiColor = NSColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(NSColor(hue: h, saturation: s, brightness: max(0, b - amount), alpha: a))
    }
    
    func lighter(by amount: CGFloat = 0.1) -> Color {
        let uiColor = NSColor(self)
        
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(NSColor(hue: h, saturation: s, brightness: min(1, b + amount), alpha: a))
    }
}
