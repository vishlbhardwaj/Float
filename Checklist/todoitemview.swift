import SwiftUI
import AppKit

struct TodoItemView: View {
    let item: TodoItem
    var isEditing: Bool
    let note: StickyNote
    var onStartEditing: () -> Void
    var onToggle: () -> Void
    var onUpdate: (String) -> Void
    var onDelete: () -> Void
    var onInsertAfter: () -> Void
    var onColorChange: (Color, NSRange?) -> Void

    @State private var itemHeight: CGFloat = 0
    @State private var isWrapping: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Checkbox
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isCompleted ? .gray : .gray.opacity(0.4))
                .font(.system(size: 16))
                .frame(width: 24, alignment: .center)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onToggle()
                    }
                }
            
            // Text field with improved wrapping behavior
            CustomTextField(
                text: Binding(
                    get: { item.text },
                    set: { onUpdate($0) }
                ),
                isFocused: isEditing,
                textColor: item.textColor,
                fontSize: item.fontSize,
                fontStyle: item.fontStyle,
                isCompleted: item.isCompleted,
                selectedRange: .constant(nil),
                onUpdate: { _ in },
                onSubmit: onInsertAfter,
                onDelete: onDelete,
                onColorChange: onColorChange,
                note: note
            )
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: TextHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            )
            .onPreferenceChange(TextHeightPreferenceKey.self) { height in 
                if height != itemHeight {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        itemHeight = height
                        isWrapping = true
                    }
                    
                    // Reset wrapping state after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isWrapping = false
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                onStartEditing()
            }
        }
        .frame(height: itemHeight)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemHeight)
        .scaleEffect(y: isWrapping ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isWrapping)
    }
}

// Add height preference key
struct TextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Custom NSTextField wrapper that handles text layout
struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var textColor: Color
    var fontSize: FontSize
    var fontStyle: FontStyle
    var isCompleted: Bool
    @Binding var selectedRange: NSRange?
    var onUpdate: (NSRange?) -> Void
    var onSubmit: () -> Void
    var onDelete: () -> Void
    var onColorChange: (Color, NSRange?) -> Void
    var note: StickyNote
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isEditable = true
        textField.isBordered = false
        textField.drawsBackground = false
        textField.delegate = context.coordinator
        
        // Configure text container options
        if let cell = textField.cell as? NSTextFieldCell {
            cell.wraps = true
            cell.isScrollable = false
            cell.truncatesLastVisibleLine = false
            cell.usesSingleLineMode = false
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.lineSpacing = 2
            
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle
            ]
            
            cell.attributedStringValue = NSAttributedString(string: "", attributes: attributes)
        }
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
        nsView.font = fontStyle.font(size: fontSize.size)
        nsView.textColor = NSColor(textColor).withAlphaComponent(isCompleted ? 0.5 : 1.0)
        
        // Fix: Properly handle optional NSResponder and boolean comparison
        if isFocused {
            DispatchQueue.main.async {
                guard let window = nsView.window,
                      let firstResponder = window.firstResponder else {
                    return
                }
                
                if !firstResponder.isEqual(nsView) {
                    window.makeFirstResponder(nsView)
                    if let editor = nsView.currentEditor() {
                        editor.selectedRange = NSRange(location: text.count, length: 0)
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomTextField
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            if commandSelector == #selector(NSResponder.deleteBackward(_:)), parent.text.isEmpty {
                parent.onDelete()
                return true
            }
            return false
        }
    }
}
