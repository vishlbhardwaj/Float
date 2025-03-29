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
    private let contentPadding: CGFloat = 30 // Base padding value
    private let headerTopOffset: CGFloat = -16 // More negative offset to push header further up
    private let topPadding: CGFloat = 24 // Slightly reduced top padding
    private let bottomSafeArea: CGFloat = 10 // Safe area at the bottom
    private let contentAreaHeight: CGFloat = 320 // Calculated height for content area
    private let checkboxWidth: CGFloat = 30 // Adjusted checkbox width for alignment
    private let dateLeftOffset: CGFloat = 4 // Small offset to align date with checkboxes
    
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
                                        // Add spacer at the top to balance the left padding
                                        Spacer().frame(height: 22)
                                        
                                        // Header with date and menu - pushed up with offset
                                        HStack(spacing: 0) {
                                            // Date with small offset to align with checkboxes
                                            HStack(spacing: 0) {
                                                Spacer().frame(width: dateLeftOffset)
                                                Text(formattedDate)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                            }
                                            .frame(width: 100, alignment: .leading) // Fixed width for date
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                    showPropertiesBar.toggle()
                                                }
                                            }) {
                                                Image(systemName: showPropertiesBar ? "xmark.circle.fill" : "ellipsis")
                                                            .foregroundColor(.gray.opacity(0.5))
                                                            .font(.system(size: 20))
                                                            .frame(width: 20, height: 20) // Keep the image size the same
                                                            .contentShape(Rectangle()) // Make entire area tappable
                                                            .frame(width: 44, height: 44) // Increase the tap target to 44x44
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .opacity(isDragging ? 0 : 1)
                                        }
                                        .offset(y: headerTopOffset) // Increased negative offset
                                        
                                        Spacer().frame(height: 10 + headerTopOffset) // Reduced spacing + adjusted for header offset
                                        
                                        // Content area
                                        VStack(alignment: .leading, spacing: 0) {
                                            todoListContent
                                        }
                                    }
                                    .padding(.horizontal, contentPadding)
                                    .padding(.top, topPadding) // Reduced top padding
                                    .padding(.bottom, contentPadding)
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
        // Wrap existing ScrollView in ZStack while preserving all original properties
        ZStack(alignment: .bottom) {
                    // Main scroll view with adjusted height to reach red line
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(alignment: .leading, spacing: 12) {
                                if note.items.isEmpty {
                                    emptyStateView
                                } else {
                                    todoItemsList(proxy: proxy)
                                }
                                
                                // Reduced spacer for less extra space at bottom
                                Spacer().frame(height: 5) // Changed from bottomSafeArea (10)
                            }
                            .onAppear {
                                scrollProxy = proxy
                            }
                            .onChange(of: editingItemId) { newValue in
                                if let id = newValue {
                                    // Auto-scroll to the editing item with a slight delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation {
                                            proxy.scrollTo(id, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    // Better height calculation to show more content
                    .frame(height: noteHeight - topPadding - contentPadding - 40) // Changed from contentAreaHeight-based calculation
                    .scrollIndicators(.visible)
                    .onTapGesture {
                        isViewActive = true
                        handleTap()
                    }
                    
                    // Bottom gradient positioned at red line
                    LinearGradient(
                        gradient: Gradient(colors: [
                            note.style.backgroundColor.opacity(0.0),  // Transparent start
                            note.style.backgroundColor.opacity(0.1),  // Very subtle start of fade
                            note.style.backgroundColor.opacity(0.4),  // Medium fade
                            note.style.backgroundColor                // Full opacity at bottom
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 20) // Taller gradient
                    .padding(.bottom, 0) // Positioned right at the visible bottom
                    .allowsHitTesting(false)
                }
                // Overall frame matched to scroll view height
                .frame(height: noteHeight - topPadding - contentPadding - 40) // Match the new height calculation
            }
    
    private var emptyStateView: some View {
    
            HStack(alignment: .center, spacing: 8) { // Added explicit spacing of 8 points
                // Always show checkbox in default state
                Image(systemName: newItemText.isEmpty ? "circle.dotted" : "circle")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                    .opacity(newItemText.isEmpty ? 0.4 : 1) // Lighter in empty state, normal when typing
                    .frame(width: checkboxWidth, alignment: .center)
                
                TextField("", text: $newItemText)
                    .font(Font(selectedFontStyle.font(size: selectedFontSize.size)))
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(selectedColor)
                    .focused($isFocused)
                    .placeholder(when: newItemText.isEmpty) {
                        Text("Add to do items") // Updated placeholder text to match your image
                            .foregroundColor(.gray.opacity(0.4)) // Reduced opacity
                            .font(Font(selectedFontStyle.font(size: selectedFontSize.size)))
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
            .padding(.vertical, 8) // Maintained vertical padding
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
                        
                        // Auto-scroll when text is updated
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
