import SwiftUI
import AppKit

struct TodoItemView: View {
    @ObservedObject var item: TodoItem
    @ObservedObject var note: StickyNote
    
    let onStartEditing: () -> Void
    let onUpdate: (String) -> Void
    let onDelete: () -> Void
    let onInsertAfter: () -> Void
    let onColorChange: (Color, NSRange?) -> Void
    
    @State private var text: String
    @State private var isPressed: Bool = false
    @State private var selectedRange: NSRange?
    @State private var isEditing: Bool
    
    init(item: TodoItem,
         note: StickyNote,
         onStartEditing: @escaping () -> Void,
         onUpdate: @escaping (String) -> Void,
         onDelete: @escaping () -> Void,
         onInsertAfter: @escaping () -> Void,
         onColorChange: @escaping (Color, NSRange?) -> Void) {
        self.item = item
        self.note = note
        self.onStartEditing = onStartEditing
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onInsertAfter = onInsertAfter
        self.onColorChange = onColorChange
        self._text = State(initialValue: item.text)
        self._isEditing = State(initialValue: false)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if note.listStyle == .checkbox {
                Button(action: {
                    if !item.text.isEmpty {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                item.isCompleted.toggle()
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
            }
            
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
                            item.isCompleted.toggle()
                        }
                        onUpdate(newText)
                    },
                    onSubmit: onInsertAfter,
                    onDelete: onDelete,
                    onColorChange: onColorChange
                )
                .frame(maxWidth: .infinity)
            } else {
                Text(item.text)
                    .font(Font(item.fontStyle.font(size: note.fontSize.size)))
                    .foregroundColor(item.textColor)
                    .strikethrough(note.listStyle == .checkbox && item.isCompleted)
                    .opacity(note.listStyle == .checkbox && item.isCompleted ? 0.6 : 1.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .onTapGesture { onStartEditing() }
                    .contentShape(Rectangle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}
