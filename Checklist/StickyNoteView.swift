import SwiftUI
import AppKit
import ConfettiSwiftUI

struct StickyNoteView: View {
    @ObservedObject var note: StickyNote
    @State private var editingItem: TodoItem?
    @State private var editingItemId: UUID?
    @State private var newItemText: String = ""
    @FocusState private var isFocused: Bool
    @State private var isDragging: Bool = false
    @State private var opacity: Double = 1.0
    @State private var scrollProxy: ScrollViewProxy?
    @State private var shadowRadius: CGFloat = 4
    @State private var elevation: CGFloat = 1.0
    @State private var shadowOpacity: Double = 0.1
    @State private var rotation: Double = 0
    @State private var confettiTrigger: Int = 0
    @State private var showCheckbox: Bool = false
    @State private var scrollTrigger: Int = 0
    @State private var dragRotation: Double = 0
    @State private var followThroughRotation: Double = 0
    @State private var lastDragValue: CGFloat = 0
    @State private var isViewActive: Bool = false
    @State private var showPropertiesBar: Bool = false
    @State private var selectedColor: Color = .primary
    @State private var selectedFontSize: FontSize = .medium
    @State private var selectedFontStyle: FontStyle = .simple
    @State private var currentEditingIndex: Int = 0
    let creationDate: Date = Date()
    var onDelete: () -> Void
    
    // Computed dimensions and spacing
    private var noteWidth: CGFloat { note.noteSize.dimensions.width }
    private var noteHeight: CGFloat { note.noteSize.dimensions.height }
    private let horizontalPadding: CGFloat = 24
    private let contentTopPadding: CGFloat = 16
    private let headerTopOffset: CGFloat = -8
    private let checkboxWidth: CGFloat = 24
    private let dateLeftOffset: CGFloat = 4
    private let bottomSafeArea: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isViewActive = false
                        isFocused = false
                        editingItemId = nil
                    }
                
                // Properties bar overlay with enhanced animation
                if showPropertiesBar && !isDragging {
                    VStack {
                        PropertiesBar(
                            note: note,
                            onDelete: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    opacity = 0
                                    showPropertiesBar = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    onDelete()
                                }
                            },
                            selectedColor: $selectedColor,
                            selectedFontSize: Binding(
                                get: { note.fontSize },
                                set: { note.updateTextSize(to: $0) }
                            ),
                            selectedFontStyle: $selectedFontStyle
                        )
                        .frame(width: 320)
                        .scaleEffect(showPropertiesBar ? 1 : 0.9)
                        .offset(y: showPropertiesBar ? -50 : -35)
                        .opacity(showPropertiesBar ? 1 : 0)
                        Spacer()
                    }
                }
                
                // Main sticky note with computed width
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(note.style.backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                note.style.backgroundColor.darker(by: 0.1),
                                lineWidth: 1
                            )
                            .opacity(0.3)
                        )
                        .shadow(
                            color: Color.black.opacity(isDragging ? 0.3 : 0.1),
                            radius: isDragging ? 20 : 10,
                            x: 0,
                            y: isDragging ? 10 : 5
                        )
                        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: noteWidth)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: noteHeight)
                    
                    VStack(spacing: 0) {
                        // Header with properties bar
                        PropertiesBar(note: note)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        
                        // Todo items list
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(note.items) { currentItem in
                                    TodoItemView(
                                        item: currentItem, 
                                        note: note,
                                        onStartEditing: { 
                                            editingItem = currentItem 
                                        },
                                        onUpdate: { newText in 
                                            currentItem.text = newText 
                                        },
                                        onDelete: {
                                            if let index = note.items.firstIndex(where: { $0.id == currentItem.id }) {
                                                if note.items.count > 1 {
                                                    note.items.remove(at: index)
                                                }
                                            }
                                        },
                                        onInsertAfter: {
                                            if let index = note.items.firstIndex(where: { $0.id == currentItem.id }) {
                                                let newItem = TodoItem()
                                                newItem.parentNote = note
                                                note.items.insert(newItem, at: index + 1)
                                                editingItem = newItem
                                            }
                                        },
                                        onColorChange: { color, range in
                                            currentItem.textColor = color
                                        }
                                    )
                                }
                                // Add new item button
                                Button(action: {
                                    let newItem = TodoItem()
                                    newItem.parentNote = note
                                    note.items.append(newItem)
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add item")
                                    }
                                    .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                    }
                    .frame(width: noteWidth, height: noteHeight)
                    .background(note.style.backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    confettiLayer
                }
                .frame(width: noteWidth, height: noteHeight)
                .cornerRadius(20)
                .scaleEffect(elevation)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .gesture(dragGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var confettiLayer: some View {
        Color.clear
            .confettiCannon(
                trigger: $confettiTrigger,
                num: 50,
                confettis: [.shape(.circle), .shape(.triangle)],
                colors: [.red, .green, .yellow, .pink, .purple],
                openingAngle: Angle(degrees: 0),
                closingAngle: Angle(degrees: 360),
                radius: 200,
                repetitions: 1,
                repetitionInterval: 0.1
            )
    }
    
    private var deleteButton: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDelete()
            }
        }) {
            Text("Move to Trash")
            Image(systemName: "trash")
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.65)) {
                        isDragging = true
                        elevation = 1.08
                        if showPropertiesBar {
                            showPropertiesBar = false
                        }
                    }
                }
                
                let dragX = value.translation.width
                let targetRotation = min(max(dragX * 0.2, -10), 10)
                
                withAnimation(.interactiveSpring()) {
                    dragRotation = targetRotation
                }
                
                lastDragValue = dragX
            }
            .onEnded { value in
                let velocity = lastDragValue * 0.05
                isDragging = false
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dragRotation = 0
                    elevation = 0.97
                }
                
                if abs(velocity) > 0.5 {
                    handleDragEndAnimation(velocity: velocity)
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.5)) {
                    elevation = 1.0
                }
                
                lastDragValue = 0
            }
    }
    
    private func handleDragEndAnimation(velocity: CGFloat) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            followThroughRotation = velocity * 0.5
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2)) {
            followThroughRotation = -velocity * 0.2
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.4)) {
            followThroughRotation = 0
        }
    }
    
    private var hasEmptyItem: Bool {
        note.items.contains { $0.text.isEmpty }
    }
    
    private var sortedItems: [TodoItem] {
        note.items.sorted { item1, item2 in
            if item1.isCompleted == item2.isCompleted {
                return item1.createdAt < item2.createdAt
            }
            return !item1.isCompleted && item2.isCompleted
        }
    }
    
    private var allItemsCompleted: Bool {
        !note.items.isEmpty && note.items.allSatisfy { $0.isCompleted }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: creationDate)
    }
    
    private func checkCompletion() {
        if allItemsCompleted && !note.items.isEmpty {
            confettiTrigger += 1
        }
    }
    
    private func handleTap() {
        if !hasEmptyItem {
            let newItem = TodoItem(
                text: "",
                isCompleted: false,
                textColor: selectedColor,
                fontSize: selectedFontSize,
                fontStyle: selectedFontStyle
            )
            note.items.append(newItem)
            editingItemId = newItem.id
        } else {
            if let emptyItem = note.items.first(where: { $0.text.isEmpty }) {
                editingItemId = emptyItem.id
            }
        }
    }
    
    private func handleMoveToPreviousItem() {
        if currentEditingIndex > 0 {
            currentEditingIndex -= 1
            editingItemId = note.items[currentEditingIndex].id
            scrollProxy?.scrollTo(editingItemId, anchor: .center)
        }
    }
    
    private func handleMoveToNextItem() {
        if currentEditingIndex < note.items.count - 1 {
            currentEditingIndex += 1
            editingItemId = note.items[currentEditingIndex].id
            scrollProxy?.scrollTo(editingItemId, anchor: .center)
        }
    }
}

// Extension for placeholder text with custom color
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
