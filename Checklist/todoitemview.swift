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
        HStack(alignment: .top, spacing: 12) {
            // List marker (checkbox or bullet)
            Group {
                if note.listStyle == .checkbox {
                    Button(action: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                onToggle()
                                isPressed = false
                            }
                        }
                    }) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(item.isCompleted ? .black : .gray)
                            .font(.system(size: item.fontSize.size))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isPressed ? 0.8 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                        .padding(.top, 8)
                }
            }
            .frame(width: 20)
            
            if isEditing {
                // Fixed layout for editing state
                CustomTextField(
                    text: $text,
                    isFocused: true,
                    textColor: item.textColor,
                    fontSize: item.fontSize,
                    fontStyle: item.fontStyle,
                    isCompleted: note.listStyle == .checkbox && item.isCompleted,
                    selectedRange: $selectedRange,
                    onUpdate: onUpdate,
                    onSubmit: onInsertAfter,
                    onDelete: onDelete,
                    onColorChange: onColorChange
                )
                .frame(minWidth: 250, maxWidth: .infinity, alignment: .leading)
                .opacity(note.listStyle == .checkbox && item.isCompleted ? 0.6 : 1.0)
                .fixedSize(horizontal: false, vertical: true)
                .animation(
                    .interpolatingSpring(
                        mass: 1.0,
                        stiffness: 100,
                        damping: 20,
                        initialVelocity: 0
                    ),
                    value: item.fontSize.size
                )
                .animation(
                    .interpolatingSpring(
                        mass: 1.0,
                        stiffness: 100,
                        damping: 20,
                        initialVelocity: 0
                    ),
                    value: item.fontStyle
                )
                // Add this to force refresh when text color changes
                .id("edit-\(item.id)-\(item.textColor.description)-\(item.fontStyle.rawValue)")
            } else {
                // Fixed layout for non-editing state
                Text(item.text)
                    .font(Font(item.fontStyle.font(size: item.fontSize.size)))
                    .foregroundColor(item.textColor)
                    .strikethrough(note.listStyle == .checkbox && item.isCompleted)
                    .opacity(note.listStyle == .checkbox && item.isCompleted ? 0.6 : 1.0)
                    .frame(minWidth: 250, maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .onTapGesture { onStartEditing() }
                    .contentShape(Rectangle())
                    .animation(
                        .interpolatingSpring(
                            mass: 1.0,
                            stiffness: 100,
                            damping: 20,
                            initialVelocity: 0
                        ),
                        value: item.fontSize.size
                    )
                    .animation(
                        .interpolatingSpring(
                            mass: 1.0,
                            stiffness: 100,
                            damping: 20,
                            initialVelocity: 0
                        ),
                        value: item.fontStyle
                    )
                    // Add this to force refresh when text color changes
                    .id("text-\(item.id)-\(item.textColor.description)-\(item.fontStyle.rawValue)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: item.isCompleted)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: note.listStyle)
    }
}

// No changes needed to CustomTextField implementation
// ... rest of the code remains the same ...

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
            
            // Ensure minimum width
            let minWidth: CGFloat = 250
            let width = max(super.intrinsicContentSize.width, minWidth)
            
            let size = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: preferredMaxLayoutWidth, height: CGFloat.greatestFiniteMagnitude))
            return NSSize(width: width, height: size.height)
        }
        
        override func textDidChange(_ notification: Notification) {
            super.textDidChange(notification)
            invalidateIntrinsicContentSize()
            
            // Force layout update
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
        textField.preferredMaxLayoutWidth = 270
        
        // Set minimum width to prevent text cutoff
        textField.setContentCompressionResistancePriority(.required, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // Add width constraint
        let widthConstraint = textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 250)
        widthConstraint.isActive = true
        
        return textField
    }
    
    func updateNSView(_ nsView: MultilineTextField, context: Context) {
        // Store the font and color values
        nsView.fontSizeValue = fontSize.size
        nsView.fontStyleValue = fontStyle
        nsView.textColorValue = NSColor(textColor)
        
        // Always update the font and color to ensure they reflect the current settings
        nsView.font = fontStyle.font(size: fontSize.size)
        nsView.textColor = NSColor(textColor)
        
        // Apply strikethrough if completed
        if isCompleted {
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: text.count))
            attributedString.addAttribute(.foregroundColor, value: NSColor(textColor).withAlphaComponent(0.6), range: NSRange(location: 0, length: text.count))
            attributedString.addAttribute(.font, value: fontStyle.font(size: fontSize.size), range: NSRange(location: 0, length: text.count))
            nsView.attributedStringValue = attributedString
        } else {
            // Only update the string value if it's different to avoid layout jumps
            if nsView.stringValue != text {
                nsView.stringValue = text
            }
            
            // Create an attributed string with the correct color and font
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttribute(.foregroundColor, value: NSColor(textColor), range: NSRange(location: 0, length: text.count))
            attributedString.addAttribute(.font, value: fontStyle.font(size: fontSize.size), range: NSRange(location: 0, length: text.count))
            nsView.attributedStringValue = attributedString
        }
        
        nsView.isCompleted = isCompleted
        
        // Ensure layout is updated properly
        DispatchQueue.main.async {
            nsView.needsLayout = true
            nsView.superview?.needsLayout = true
            
            if isFocused {
                nsView.becomeFirstResponder()
                if let editor = nsView.currentEditor() {
                    if let range = selectedRange {
                        editor.selectedRange = range
                    } else {
                        let range = NSRange(location: nsView.stringValue.count, length: 0)
                        editor.selectedRange = range
                    }
                    
                    // Apply text attributes to the field editor
                    if let textView = editor as? NSTextView {
                        let editorString = NSMutableAttributedString(string: text)
                        
                        if isCompleted {
                            editorString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: text.count))
                            editorString.addAttribute(.foregroundColor, value: NSColor(textColor).withAlphaComponent(0.6), range: NSRange(location: 0, length: text.count))
                        } else {
                            editorString.addAttribute(.foregroundColor, value: NSColor(textColor), range: NSRange(location: 0, length: text.count))
                        }
                        
                        editorString.addAttribute(.font, value: fontStyle.font(size: fontSize.size), range: NSRange(location: 0, length: text.count))
                        
                        // Save selection
                        let selection = textView.selectedRange
                        
                        // Apply attributes
                        textView.textStorage?.setAttributedString(editorString)
                        
                        // Restore selection
                        textView.setSelectedRange(selection)
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
                            // Always apply the text color
                            editorString.addAttribute(.foregroundColor, value: textField.textColorValue, range: NSRange(location: 0, length: textField.stringValue.count))
                        }
                        
                        editorString.addAttribute(.font, value: textField.fontStyleValue.font(size: textField.fontSizeValue), range: NSRange(location: 0, length: textField.stringValue.count))
                        
                        // Save selection
                        let selection = textView.selectedRange
                        
                        // Apply attributes
                        textView.textStorage?.setAttributedString(editorString)
                        
                        // Restore selection
                        textView.setSelectedRange(selection)
                    }
                }
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
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
