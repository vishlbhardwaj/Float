import SwiftUI
import AppKit
import ConfettiSwiftUI

struct StickyNoteView: View {
    @ObservedObject var note: StickyNote
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
    @State private var selectedColor: Color = .black
    @State private var selectedFontSize: FontSize = .medium
    @State private var selectedFontStyle: FontStyle = .simple
    let creationDate: Date = Date()
    var onDelete: () -> Void
    
    // Fixed dimensions and spacing
    private let noteWidth: CGFloat = 350
    private let noteHeight: CGFloat = 420
    private let horizontalPadding: CGFloat = 24
    private let contentTopPadding: CGFloat = 20
    private let headerTopOffset: CGFloat = -12
    private let checkboxWidth: CGFloat = 24
    private let dateLeftOffset: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isViewActive = false
                        isFocused = false
                        editingItemId = nil
                    }
                
                // Main sticky note with fixed width
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
                    
                    // Content with explicit padding
                    VStack(alignment: .leading, spacing: 0) {
                        // Top spacer adjusted
                        Spacer().frame(height: 16)
                        
                        // Header section
                        HStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Spacer().frame(width: dateLeftOffset)
                                Text(formattedDate)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 100, alignment: .leading)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showPropertiesBar.toggle()
                                }
                            }) {
                                Image(systemName: showPropertiesBar ? "xmark.circle.fill" : "ellipsis")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .font(.system(size: 20))
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(isDragging ? 0 : 1)
                        }
                        .offset(y: headerTopOffset)
                        
                        Spacer().frame(height: 8)
                        
                        // Content area with improved spacing
                        VStack(alignment: .leading, spacing: 0) {
                            todoListContent
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, contentTopPadding)
                    .frame(width: noteWidth, height: noteHeight)
                    
                    confettiLayer
                }
                .frame(width: noteWidth, height: noteHeight)
                .cornerRadius(20)
                .scaleEffect(elevation)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                
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
                            selectedFontSize: $selectedFontSize,
                            selectedFontStyle: $selectedFontStyle
                        )
                        .frame(width: 320)
                        .scaleEffect(showPropertiesBar ? 1 : 0.9)
                        .offset(y: showPropertiesBar ? 0 : -15)
                        .opacity(showPropertiesBar ? 1 : 0)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9)
                                .combined(with: .offset(y: -15))
                                .combined(with: .opacity),
                            removal: .scale(scale: 0.9)
                                .combined(with: .offset(y: -15))
                                .combined(with: .opacity)
                        ))
                        Spacer()
                    }
                    .offset(y: 10)
                }
            }
            .frame(width: 500, height: 570, alignment: .center)
            .animation(.default, value: isDragging)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showPropertiesBar)
            .animation(.spring(response: 0.3, dampingFraction: isDragging ? 0.65 : 0.8), value: elevation)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: rotation)
            .gesture(dragGesture)
            .rotationEffect(.degrees(dragRotation + followThroughRotation))
            .onTapGesture { }
            .onAppear {
                isFocused = true
                selectedFontStyle = note.fontStyle
            }
            .contextMenu { deleteButton }
            .onChange(of: selectedFontSize) { newSize in
                note.updateTextSizeSmoothly(to: newSize)
            }
            .onChange(of: selectedFontStyle) { newStyle in
                note.fontStyle = newStyle
                
                note.isShimmering = true
                
                for index in note.items.indices {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        note.items[index].fontStyle = newStyle
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        note.isShimmering = false
                    }
                }
            }
        }
    }
    
    private var todoListContent: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 8) {
                        if note.items.isEmpty {
                            emptyStateView
                        } else {
                            todoItemsList(proxy: proxy)
                        }
                        
                        Spacer().frame(height: 5)
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: editingItemId) { newValue in
                        if let id = newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: noteHeight - contentTopPadding - horizontalPadding - 40)
            .scrollIndicators(.visible)
            .onTapGesture {
                isViewActive = true
                handleTap()
            }
            
            LinearGradient(
                gradient: Gradient(colors: [
                    note.style.backgroundColor.opacity(0.0),
                    note.style.backgroundColor.opacity(0.1),
                    note.style.backgroundColor.opacity(0.4),
                    note.style.backgroundColor
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            .padding(.bottom, 0)
            .allowsHitTesting(false)
        }
        .frame(height: noteHeight - contentTopPadding - horizontalPadding - 40)
    }
    
    private var emptyStateView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: newItemText.isEmpty ? "circle.dotted" : "circle")
                .foregroundColor(newItemText.isEmpty ? .gray.opacity(0.4) : .gray)
                .font(.system(size: 16))
                .frame(width: checkboxWidth, alignment: .center)
                .allowsHitTesting(false) // Disable interaction when empty
            
            TextField("", text: $newItemText)
                .font(Font(selectedFontStyle.font(size: selectedFontSize.size)))
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(selectedColor)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: noteWidth - horizontalPadding * 2 - checkboxWidth - 8, alignment: .leading) // Explicit width calculation
                .focused($isFocused)
                .placeholder(when: newItemText.isEmpty) {
                    Text("Add to do items")
                        .foregroundColor(.gray.opacity(0.4))
                        .font(Font(selectedFontStyle.font(size: selectedFontSize.size)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onSubmit {
                    if !newItemText.isEmpty {
                        let firstItem = TodoItem(
                            text: newItemText,
                            isCompleted: false,
                            textColor: selectedColor,
                            fontSize: selectedFontSize,
                            fontStyle: selectedFontStyle
                        )
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            note.items.append(firstItem)
                            newItemText = ""
                            
                            let newItem = TodoItem(
                                text: "",
                                isCompleted: false,
                                textColor: selectedColor,
                                fontSize: selectedFontSize,
                                fontStyle: selectedFontStyle
                            )
                            note.items.append(newItem)
                            editingItemId = newItem.id
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollProxy?.scrollTo(newItem.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .onChange(of: newItemText) { newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCheckbox = !newValue.isEmpty
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: newItemText.isEmpty)
    }
    
    private func todoItemsList(proxy: ScrollViewProxy) -> some View {
        ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
            TodoItemView(
                item: item,
                isEditing: editingItemId == item.id,
                note: note,
                onStartEditing: {
                    editingItemId = item.id
                },
                onToggle: {
                    if let index = note.items.firstIndex(where: { $0.id == item.id }) {
                        note.items[index].isCompleted.toggle()
                        checkCompletion()
                    }
                },
                onUpdate: { newText in
                    if let index = note.items.firstIndex(where: { $0.id == item.id }) {
                        note.items[index].text = newText
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation {
                                proxy.scrollTo(item.id, anchor: .bottom)
                            }
                        }
                    }
                },
                onDelete: {
                    if let index = note.items.firstIndex(where: { $0.id == item.id }) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            note.items.remove(at: index)
                            
                            if !note.items.isEmpty {
                                let newIndex = max(0, index - 1)
                                let newItem = note.items[newIndex]
                                editingItemId = newItem.id
                            } else {
                                editingItemId = nil
                                isFocused = true
                            }
                        }
                    }
                },
                onInsertAfter: {
                    if let index = note.items.firstIndex(where: { $0.id == item.id }) {
                        let newItem = TodoItem(
                            text: "",
                            isCompleted: false,
                            textColor: selectedColor,
                            fontSize: selectedFontSize,
                            fontStyle: selectedFontStyle
                        )
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            note.items.insert(newItem, at: index + 1)
                            editingItemId = newItem.id
                        }
                    }
                },
                onColorChange: { color, range in
                    if let index = note.items.firstIndex(where: { $0.id == item.id }) {
                        note.items[index].textColor = color
                    }
                }
            )
            .id(item.id)
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
            .onChanged(handleDragChange)
            .onEnded(handleDragEnd)
    }
    
    private func handleDragChange(_ value: DragGesture.Value) {
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
        let targetRotation = dragX * 0.5
        
        withAnimation(.interactiveSpring()) {
            dragRotation = min(max(targetRotation, -15), 15)
        }
        
        lastDragValue = dragX
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        let velocity = lastDragValue * 0.08
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
