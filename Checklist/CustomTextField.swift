import SwiftUI
import AppKit

struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    let isFocused: Bool
    let textColor: Color
    let fontSize: FontSize
    let fontStyle: FontStyle
    let isCompleted: Bool
    @Binding var selectedRange: NSRange?
    let onUpdate: (String) -> Void
    let onSubmit: () -> Void
    let onDelete: () -> Void
    let onColorChange: (Color, NSRange?) -> Void
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            parent.text = textField.stringValue
            parent.onUpdate(textField.stringValue)
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                if parent.text.isEmpty {
                    parent.onDelete()
                    return true
                }
            }
            return false
        }
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.stringValue = text
        textField.isBordered = false
        textField.drawsBackground = false
        textField.textColor = NSColor(textColor)
        textField.font = fontStyle.font(size: fontSize.size)
        textField.focusRingType = .none
        textField.lineBreakMode = .byWordWrapping
        textField.cell?.wraps = true
        textField.cell?.scrollable = false
        textField.cell?.usesSingleLineMode = false
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
        nsView.textColor = NSColor(textColor)
        nsView.font = fontStyle.font(size: fontSize.size)
        
        if isFocused {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}