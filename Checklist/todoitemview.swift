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
    let index: Int
    let totalItems: Int
    
    @State private var text: String
    @State private var isPressed: Bool = false
    @State private var selectedRange: NSRange?
    @State private var opacity: Double = 1.0
    @State private var blurRadius: CGFloat = 0
    @State private var verticalOffset: CGFloat = 20
    @State private var scale: CGFloat = 1
    @State private var isUpdatingSize: Bool = false
    @State private var currentFontSize: FontSize
    @State private var isTransitioning: Bool = false
    
    private var itemHeight: CGFloat {
        currentFontSize.size * 1.8
    }
    
    init(item: TodoItem,
         isEditing: Bool,
         note: StickyNote,
         index: Int,
         totalItems: Int,
         onStartEditing: @escaping () -> Void,
         onToggle: @escaping () -> Void,
         onUpdate: @escaping (String) -> Void,
         onDelete: @escaping () -> Void,
         onInsertAfter: @escaping () -> Void,
         onColorChange: @escaping (Color, NSRange?) -> Void) {
        self.item = item
        self.isEditing = isEditing
        self.note = note
        self.index = index
        self.totalItems = totalItems
        self.onStartEditing = onStartEditing
        self.onToggle = onToggle
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onInsertAfter = onInsertAfter
        self.onColorChange = onColorChange
        self._text = State(initialValue: item.text)
        self._currentFontSize = State(initialValue: note.fontSize)
    }
    
    private func performResizeAnimation() {
        // Immediately update the font size
        currentFontSize = note.fontSize

        // Set initial hidden state before animation
        opacity = 0
        scale = 0.98
        blurRadius = 10
        isUpdatingSize = true
        
        // Apply staggered appear animations
        let staggerDelay = Double(index) * 0.05

        // Restore opacity and remove blur with a simple fade (no bounce)
        withAnimation(.easeIn(duration: 0.35).delay(staggerDelay)) { // Slower duration
            opacity = 1
            blurRadius = 0
        }

        // Apply bouncy spring to scale
        withAnimation(.spring(
            response: 0.6, // Slower response
            dampingFraction: 0.4
        ).delay(staggerDelay)) {
            scale = 1
            isUpdatingSize = false // Ensure this is set when scale animation ends
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Conditionally show Checkbox or Bullet
            if note.listStyle == .checkbox {
                checkboxButton()
            } else {
                bulletPoint()
            }
            
            // Text Content (Editing or Display)
            textContent()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .background(Color.clear)
        .onChange(of: note.fontSize) { _, _ in
            performResizeAnimation()
        }
        .onChange(of: item.fontStyle) { _, _ in
            performResizeAnimation()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func checkboxButton() -> some View {
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
                .foregroundColor(item.text.isEmpty ? .gray : (item.isCompleted ? .black : .gray))
                .font(.system(size: currentFontSize.size))
                .opacity(item.text.isEmpty ? 0.6 : (item.isCompleted ? 1 : 1))
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.8 : 1.0)
        .opacity(isTransitioning ? 0 : opacity) // Keep opacity/scale for animations
        .scaleEffect(scale)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .allowsHitTesting(!item.text.isEmpty)
        .frame(width: 24, alignment: .center)
        .offset(y: 2)
    }
    
    @ViewBuilder
    private func bulletPoint() -> some View {
        Text("•") // Use a bullet character
            .font(.system(size: currentFontSize.size))
            .foregroundColor(.gray) // Match color
            .opacity(opacity) // Apply animation opacity
            .scaleEffect(scale) // Apply animation scale
            .frame(width: 24, alignment: .center) // Changed alignment to .center
            .offset(y: 2) // Offset to match checkbox
    }
    
    @ViewBuilder
    private func textContent() -> some View {
        if isEditing {
            Group {
                CustomTextField(
                    text: $text,
                    isFocused: true,
                    textColor: item.textColor,
                    fontSize: currentFontSize,
                    fontStyle: item.fontStyle,
                    // Strikethrough only applies for checkbox style
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
                    onColorChange: { _, _ in /* No longer needed here */ },
                    note: note
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(opacity)
            .blur(radius: blurRadius)
            .scaleEffect(scale)
        } else {
            Group {
                Text(item.text)
                    .font(Font(item.fontStyle.font(size: currentFontSize.size)))
                    .foregroundColor(item.textColor)
                    // Strikethrough only applies for checkbox style
                    .strikethrough(note.listStyle == .checkbox && item.isCompleted)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .opacity(opacity)
            .blur(radius: blurRadius)
            .scaleEffect(scale)
            .contentShape(Rectangle())
            .onTapGesture { onStartEditing() }
        }
    }
    
    private var emptyStateView: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: item.text.isEmpty ? "circle.dotted" : "circle")
                .foregroundColor(item.text.isEmpty ? .gray.opacity(0.4) : .gray)
                .font(.system(size: note.fontSize.size))
                .opacity(item.text.isEmpty ? 0.4 : 1)
                .frame(width: 24, height: note.fontSize.size * 1.8, alignment: .center)
                .allowsHitTesting(false)
            
            CustomTextField(
                text: .constant(""),
                isFocused: true,
                textColor: .black,
                fontSize: note.fontSize,
                fontStyle: .simple,
                isCompleted: false,
                selectedRange: .constant(nil),
                onUpdate: { _ in },
                onSubmit: { },
                onDelete: { },
                onColorChange: { _, _ in },
                note: note
            )
            .frame(height: note.fontSize.size * 1.8)
            .frame(maxWidth: .infinity)
            .overlay(
                Text("Add to do items")
                    .foregroundColor(.gray.opacity(0.4))
                    .font(.init(FontStyle.simple.font(size: note.fontSize.size)))
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
        .frame(height: note.fontSize.size * 1.8)
        .frame(maxWidth: .infinity, alignment: .leading)
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
    @ObservedObject var note: StickyNote
    
    class MultilineTextField: NSTextField {
        var isCompleted: Bool = false
        var fontSizeValue: CGFloat = 16
        var fontStyleValue: FontStyle = .simple
        var textColorValue: NSColor = .textColor
        weak var note: StickyNote?
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupTextField()
        }
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupTextField()
        }
        
        private func setupTextField() {
            self.cell?.wraps = true
            self.cell?.isScrollable = false
            self.cell?.truncatesLastVisibleLine = false
            self.maximumNumberOfLines = 0
            self.lineBreakMode = .byWordWrapping
            self.usesSingleLineMode = false
        }
        
        override var intrinsicContentSize: NSSize {
            guard let cell = self.cell, let note = note else { return super.intrinsicContentSize }
            
            let width: CGFloat = max(240, note.noteSize.dimensions.width - 80)
            let height = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude)).height
            
            return NSSize(width: width, height: height)
        }
        
        override func textDidChange(_ notification: Notification) {
            super.textDidChange(notification)
            invalidateIntrinsicContentSize()
            needsLayout = true
            superview?.needsLayout = true
        }
        
        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            
            NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
                if let textView = self?.currentEditor() as? NSTextView,
                   let selectedRange = textView.selectedRanges.first?.rangeValue,
                   selectedRange.length > 0 {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowColorPicker"),
                        object: nil,
                        userInfo: ["range": selectedRange]
                    )
                }
                return event
            }
        }
    }
    
    func makeNSView(context: Context) -> MultilineTextField {
        let textField = MultilineTextField(frame: .zero)
        textField.note = note
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
        
        // Configure for proper text wrapping
        textField.preferredMaxLayoutWidth = max(240, note.noteSize.dimensions.width - 80)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.required, for: .vertical)
        textField.setContentHuggingPriority(.required, for: .vertical)
        
        return textField
    }
    
    func updateNSView(_ nsView: MultilineTextField, context: Context) {
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
        
        if let textView = nsView.currentEditor() as? NSTextView,
           let storage = textView.textStorage {
            let attributedString = NSMutableAttributedString(string: text)
            
            if isCompleted {
                attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: text.count))
                attributedString.addAttribute(.foregroundColor, value: NSColor(textColor).withAlphaComponent(0.6), range: NSRange(location: 0, length: text.count))
            } else {
                attributedString.addAttribute(.foregroundColor, value: NSColor(textColor), range: NSRange(location: 0, length: text.count))
            }
            
            attributedString.addAttribute(.font, value: fontStyle.font(size: fontSize.size), range: NSRange(location: 0, length: text.count))
            
            let selection = textView.selectedRange
            storage.setAttributedString(attributedString)
            textView.selectedRange = selection
        }
        
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
                }
            }
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  parent.isFocused // Only update if this field is supposed to be focused
            else { return }
            
            parent.selectedRange = textView.selectedRange
        }
        
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
