import SwiftUI
import AppKit

struct TodoItemView: View {
    let item: TodoItem
    let isEditing: Bool
    let onStartEditing: () -> Void
    let onToggle: () -> Void
    let onUpdate: (String) -> Void
    let onDelete: () -> Void
    let onInsertAfter: () -> Void
    let onColorChange: (Color, NSRange?) -> Void
    @ObservedObject var note: StickyNote
    
    @State private var text: String
    @State private var isPressed: Bool = false
    @State private var selectedRange: NSRange?
    
    init(item: TodoItem,
         isEditing: Bool,
         note: StickyNote,
         onStartEditing: @escaping () -> Void,
         onToggle: @escaping () -> Void,
         onUpdate: @escaping (String) -> Void,
         onDelete: @escaping () -> Void,
         onInsertAfter: @escaping () -> Void,
         onColorChange: @escaping (Color, NSRange?) -> Void) {
        self.item = item
        self.isEditing = isEditing
        self.note = note
        self.onStartEditing = onStartEditing
        self.onToggle = onToggle
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onInsertAfter = onInsertAfter
        self.onColorChange = onColorChange
        self._text = State(initialValue: item.text)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: {
                if !item.text.isEmpty {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onToggle()
                            isPressed = false
                        }
                    }
                }
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : (item.text.isEmpty ? "circle.dotted" : "circle"))
                    .foregroundColor(item.text.isEmpty ? .gray.opacity(0.4) : (item.isCompleted ? .gray : .gray))
                    .font(.system(size: note.fontSize.size))
                    .opacity(item.text.isEmpty ? 0.4 : (item.isCompleted ? 1 : 1))
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .allowsHitTesting(!item.text.isEmpty)
            .frame(width: 24, alignment: .center)
            
            if isEditing {
                CustomTextField(
                    text: $text,
                    isFocused: true,
                    textColor: item.textColor,
                    fontSize: note.fontSize,
                    fontStyle: item.fontStyle,
                    isCompleted: note.listStyle == .checkbox && item.isCompleted,
                    selectedRange: $selectedRange,
                    onUpdate: { newText in
                        if newText.isEmpty && item.isCompleted {
                            onToggle()
                        }
                        onUpdate(newText)
                    },
                    onSubmit: onInsertAfter,
                    onDelete: onDelete,
                    onColorChange: onColorChange
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .opacity(note.listStyle == .checkbox && item.isCompleted ? 0.6 : 1.0)
                .animation(.easeOut(duration: 0.2), value: item.isCompleted)
            } else {
                Text(item.text)
                    .font(Font(item.fontStyle.font(size: note.fontSize.size)))
                    .foregroundColor(item.textColor)
                    .strikethrough(note.listStyle == .checkbox && item.isCompleted)
                    .opacity(note.listStyle == .checkbox && item.isCompleted ? 0.6 : 1.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .onTapGesture { onStartEditing() }
                    .contentShape(Rectangle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

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
    
    class MultilineTextField: NSTextField {
        var isCompleted: Bool = false
        var fontSizeValue: CGFloat = 16
        var fontStyleValue: FontStyle = .simple
        var textColorValue: NSColor = .textColor
        
        override var intrinsicContentSize: NSSize {
            guard let cell = self.cell else { return super.intrinsicContentSize }
            
            // Fixed width that matches the sticky note content area
            let width: CGFloat = 290 // Leave space for checkbox and padding
            let height = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude)).height
            
            return NSSize(width: width, height: height)
        }
        
        override func textDidChange(_ notification: Notification) {
            super.textDidChange(notification)
            
            // Force immediate layout update
            invalidateIntrinsicContentSize()
            needsLayout = true
            superview?.needsLayout = true
        }
    }
    
    func makeNSView(context: Context) -> MultilineTextField {
        let textField = MultilineTextField()
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = fontStyle.font(size: fontSize.size)
        textField.fontSizeValue = fontSize.size
        textField.fontStyleValue = fontStyle
        textField.textColor = NSColor(textColor)
        textField.textColorValue = NSColor(textColor)
        textField.isCompleted = isCompleted
        
        // Configure text wrapping
        textField.cell?.wraps = true
        textField.cell?.isScrollable = false
        textField.cell?.truncatesLastVisibleLine = false
        textField.maximumNumberOfLines = 0
        textField.preferredMaxLayoutWidth = 290
        
        // Set compression and hugging priorities
        textField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        textField.setContentCompressionResistancePriority(.required, for: .vertical)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        return textField
    }
    
    func updateNSView(_ nsView: MultilineTextField, context: Context) {
        // Update properties
        nsView.fontSizeValue = fontSize.size
        nsView.fontStyleValue = fontStyle
        nsView.textColorValue = NSColor(textColor)
        nsView.font = fontStyle.font(size: fontSize.size)
        nsView.textColor = NSColor(textColor)
        nsView.isCompleted = isCompleted
        
        if nsView.stringValue != text {
            let attributedString = NSMutableAttributedString(string: text)
            if isCompleted {
                attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: text.count))
                attributedString.addAttribute(.foregroundColor, value: NSColor(textColor).withAlphaComponent(0.6), range: NSRange(location: 0, length: text.count))
            } else {
                attributedString.addAttribute(.foregroundColor, value: NSColor(textColor), range: NSRange(location: 0, length: text.count))
            }
            attributedString.addAttribute(.font, value: fontStyle.font(size: fontSize.size), range: NSRange(location: 0, length: text.count))
            nsView.attributedStringValue = attributedString
        }
        
        // Handle focus and selection
        if isFocused {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
                if let editor = nsView.currentEditor() {
                    if let range = selectedRange {
                        editor.selectedRange = range
                    } else {
                        editor.selectedRange = NSRange(location: nsView.stringValue.count, length: 0)
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
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? MultilineTextField {
                parent.text = textField.stringValue
                parent.onUpdate(textField.stringValue)
                
                if let editor = textField.currentEditor() {
                    parent.selectedRange = editor.selectedRange
                    
                    // Apply text attributes as user types
                    if let textView = editor as? NSTextView {
                        let editorString = NSMutableAttributedString(string: textField.stringValue)
                        
                        if parent.isCompleted {
                            editorString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: textField.stringValue.count))
                            editorString.addAttribute(.foregroundColor, value: textField.textColorValue.withAlphaComponent(0.6), range: NSRange(location: 0, length: textField.stringValue.count))
                        } else {
                            editorString.addAttribute(.foregroundColor, value: textField.textColorValue, range: NSRange(location: 0, length: textField.stringValue.count))
                        }
                        
                        editorString.addAttribute(.font, value: textField.fontStyleValue.font(size: textField.fontSizeValue), range: NSRange(location: 0, length: textField.stringValue.count))
                        
                        let selection = textView.selectedRange
                        textView.textStorage?.setAttributedString(editorString)
                        textView.setSelectedRange(selection)
                    }
                }
            }
        }
        
        // Handle keyboard navigation
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                NotificationCenter.default.post(name: NSNotification.Name("MoveToPreviousItem"), object: nil)
                return true
            }
            
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                NotificationCenter.default.post(name: NSNotification.Name("MoveToNextItem"), object: nil)
                return true
            }
            
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if !parent.text.isEmpty {
                    parent.onSubmit()
                }
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
}
